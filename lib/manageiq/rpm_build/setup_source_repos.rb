require 'fileutils'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class SetupSourceRepos
      include Helper

      attr_reader :git_ref

      def initialize(ref)
        where_am_i
        @git_ref = ref || OPTIONS.repos.ref
      end

      def populate
        where_am_i
        clean_build_dir
        setup_rpm_spec_repo
        setup_source_repo
      end

      def clean_build_dir
        where_am_i
        FileUtils.rm_rf BUILD_DIR
        FileUtils.mkdir_p BUILD_DIR
      end

      def setup_rpm_spec_repo
        where_am_i
        FileUtils.cp_r("/build_scripts/rpm_spec", RPM_SPEC_DIR)
      end

      def setup_source_repo
        where_am_i
        Dir.chdir(BUILD_DIR) do
          git_clone(OPTIONS.repos.manageiq_appliance_build, "manageiq-appliance-build")
          git_clone(OPTIONS.repos.manageiq_appliance, "manageiq-appliance")
          git_clone(OPTIONS.repos.manageiq, "manageiq")
          git_clone(OPTIONS.repos.manageiq_ui_service, "manageiq-ui-service")
        end
        # WORKAROUND
        FileUtils.cp(ROOT_DIR.join("evm_override"), BUILD_DIR.join("manageiq-appliance/LINK/etc/default/evm"))
        post_setup_source_repo
      end

      def post_setup_source_repo
        hook = OPTIONS_DIR.join("post_setup_source_repo")
        return unless hook.executable?

        where_am_i
        Dir.chdir(BUILD_DIR) { shell_cmd(hook) }
      end

      private

      def git_clone(repo_options, destination)
        repo_ref = repo_options.ref || git_ref
        shell_cmd("git clone --depth 1 -b #{repo_ref} #{repo_options.url} #{destination}")
      end
    end
  end
end
