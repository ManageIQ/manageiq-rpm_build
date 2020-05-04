require 'awesome_spawn'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class BuildCopr
      include Helper

      attr_reader :release_name, :rpm_release, :rpm_repo_name, :rpm_spec

      def initialize(release_name)
        @release_name  = release_name
        @rpm_release   = OPTIONS.rpm.release
        @rpm_repo_name = OPTIONS.rpm.repo_name
        @rpm_spec      = "#{OPTIONS.product_name}.spec"
      end

      def generate_rpm
        where_am_i

        Dir.chdir(RPM_SPEC_DIR) do
          generate_spec_from_subpackage_files
          update_spec

          if File.exist?(File.expand_path("~/.config/copr"))
            shell_cmd("rpmbuild -bs --define '_sourcedir #{RPM_SPEC_DIR}' --define '_srcrpmdir #{RPM_SPEC_DIR}' #{rpm_spec}")
            shell_cmd("copr-cli build -r epel-8-x86_64 #{rpm_repo_name} #{OPTIONS.product_name}-*.src.rpm")
          else
            shell_cmd("rpmbuild -bb --define '_sourcedir #{RPM_SPEC_DIR}' --define '_rpmdir #{BUILD_DIR.join("rpms")}' #{rpm_spec}")
          end
        end
      end

      def generate_spec_from_subpackage_files
        manageiq_spec = File.read("manageiq.spec.in")

        Dir.glob("subpackages/*").sort.each do |spec|
          subpackage_spec = File.read(spec)
          manageiq_spec.sub!("%changelog", "#{subpackage_spec}\n\n%changelog")
        end

        File.write(rpm_spec, manageiq_spec)
      end

      private

      def update_spec
        where_am_i

        spec_text = File.read(rpm_spec)

        spec_text.sub!("RPM_VERSION", OPTIONS.rpm.version)
        spec_text.sub!("RPM_RELEASE", spec_release)
        File.write(rpm_spec, spec_text)
      end

      def spec_release
        if release_name.empty?
          "#{rpm_release}.#{BUILD_DATE}"
        else
          pre_build = release_name.split("-")[2]
          pre_build ? "#{rpm_release}.#{pre_build}" : "#{rpm_release}"
        end
      end
    end
  end
end
