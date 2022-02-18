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
          generate_spec_from_template

          if File.exist?(File.expand_path("~/.config/copr"))
            shell_cmd("rpmbuild -bs --define '_sourcedir #{RPM_SPEC_DIR}' --define '_srcrpmdir #{RPM_SPEC_DIR}' #{rpm_spec}")
            shell_cmd("copr-cli build -r epel-8-x86_64 #{rpm_repo_name} #{OPTIONS.product_name}-*.src.rpm")
          else
            arch = RUBY_PLATFORM.split("-").first
            shell_cmd("rpmbuild -ba --define '_sourcedir #{RPM_SPEC_DIR}' --define '_srcrpmdir #{BUILD_DIR.join("rpms", arch)}' --define '_rpmdir #{BUILD_DIR.join("rpms")}' #{rpm_spec}")
          end
        end
      end

      def generate_spec_from_template
        manageiq_spec = File.read("manageiq.spec.in")

        Dir.glob("subpackages/*").sort.each do |spec|
          subpackage_spec = File.read(spec)
          manageiq_spec << "#{subpackage_spec}\n\n"
        end

        # Add changelog
        changelog = OPTIONS.rpm.changelog ? OPTIONS_DIR.join(OPTIONS.rpm.changelog) : "changelog"
        manageiq_spec << File.read(changelog)

        File.write(rpm_spec, manageiq_spec)
        update_spec
      end

      private

      def update_spec
        where_am_i

        spec_text = File.read(rpm_spec)

        spec_text.sub!("ORG_NAME", OPTIONS.rpm.org_name)
        spec_text.sub!("PRODUCT_NAME", OPTIONS.product_name)
        spec_text.sub!("PRODUCT_SUMMARY", OPTIONS.rpm.product_summary)
        spec_text.sub!("PRODUCT_URL", OPTIONS.rpm.product_url)
        spec_text.sub!("RPM_RELEASE", spec_release)
        spec_text.sub!("RPM_VERSION", OPTIONS.rpm.version)
        File.write(rpm_spec, spec_text)
      end

      def spec_release
        if release_name.empty?
          BUILD_DATE
        else
          pre_build = release_name.split("-")[2]
          pre_build ? "#{pre_build}" : "#{rpm_release}"
        end
      end
    end
  end
end
