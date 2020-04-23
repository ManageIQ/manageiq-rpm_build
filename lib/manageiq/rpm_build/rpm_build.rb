require 'awesome_spawn'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class RpmBuild
      attr_reader :rpm_name, :rpm_release, :rpm_repo_name

      def initialize(name)
        @rpm_name = name

        options        = YAML.load_file(CONFIG_DIR.join("options.yml"))
        @rpm_release   = "1.#{BUILD_DATE}"
        @rpm_repo_name = options["rpm_repo_name"]
      end

      def generate_rpm
        puts "\n---> #{self.class.name}::#{__method__}"

        Dir.chdir(RPM_SPEC_DIR.join(rpm_name)) do
          update_spec_version
          #TODO - need to allow customization
          exit $?.exitstatus unless system("rpmbuild -bs --define '_sourcedir .' --define '_srcrpmdir .' #{rpm_name}.spec")
          exit $?.exitstatus unless system("copr-cli --config /build_scripts/copr-cli-token build -r epel-8-x86_64 #{rpm_repo_name} #{rpm_name}-*.src.rpm")
        end
      end

      private

      def update_spec_version
        puts "\n---> #{self.class.name}::#{__method__}"

        spec_file = "#{rpm_name}.spec"
        spec_text = File.read(spec_file)

        spec_text.sub!("RPM_VERSION", VERSION)
        spec_text.sub!("RPM_RELEASE", rpm_release)
        File.write(spec_file, spec_text)
      end
    end
  end
end
