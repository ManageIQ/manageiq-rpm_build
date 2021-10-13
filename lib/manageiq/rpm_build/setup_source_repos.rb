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
          git_clone(OPTIONS.repos.manageiq_appliance, "manageiq-appliance")
          git_clone(OPTIONS.repos.manageiq, "manageiq")
          git_clone(OPTIONS.repos.manageiq_ui_service, "manageiq-ui-service")
        end
        setup_bundler_d_dir
        post_setup_source_repo
      end

      def setup_bundler_d_dir
        bundler_d_dir = OPTIONS_DIR.join("bundler.d")
        return unless bundler_d_dir.exist?

        FileUtils.cp_r(bundler_d_dir.glob("*"), BUILD_DIR.join("manageiq", "bundler.d"))
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
