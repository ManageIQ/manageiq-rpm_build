require 'fileutils'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class SetupSourceRepos
      include Helper

      attr_reader :git_ref, :github_url

      def initialize(ref)
        where_am_i
        options = YAML.load_file(CONFIG_DIR.join("options.yml"))

        @git_ref      = ref || options["git_ref"]
        @github_url   = options["github_url"]
      end

      def populate
        where_am_i
        clean_build_dir
        setup_rpm_spec_repo
        setup_source_repo
        FileUtils.cp(SCRIPT_DIR.join("evm_productization"), BUILD_DIR.join("manageiq-appliance/LINK/etc/default/"))
      end

      def clean_build_dir
        where_am_i
        FileUtils.rm_rf BUILD_DIR
        FileUtils.mkdir_p BUILD_DIR
      end

      def setup_rpm_spec_repo
        where_am_i
        FileUtils.mkdir_p RPM_SPEC_DIR
        FileUtils.cp_r("/build_scripts/rpm_spec", BUILD_DIR)
        Dir.chdir(RPM_SPEC_DIR) do
          #git_clone("#{github_url}/#{PRODUCT_NAME}-gemset.git")
          #git_clone("#{github_url}/#{PRODUCT_NAME}.git")
          #git_clone("#{github_url}/#{PRODUCT_NAME}-appliance.git")
        end
      end

      def setup_source_repo
        where_am_i
        Dir.chdir(BUILD_DIR) do
          git_clone("#{github_url}/#{PRODUCT_NAME}-appliance-build.git", "manageiq-appliance-build")
          git_clone("#{github_url}/#{PRODUCT_NAME}-appliance.git", "manageiq-appliance")
          git_clone("#{github_url}/#{PRODUCT_NAME}.git", "manageiq")
          git_clone("#{github_url}/#{PRODUCT_NAME}-ui-service.git", "manageiq-ui-service")
        end
      end

      private

      def git_clone(repo_url, destination = nil)
        destination ||= File.basename(repo_url, ".git")
        exit $?.exitstatus unless system("git clone --depth 1 -b #{git_ref} #{repo_url} #{destination}")
      end
    end
  end
end
