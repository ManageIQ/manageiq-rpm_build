require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class GenerateCore
      include Helper
      attr_reader :miq_dir

      def initialize
        @miq_dir = BUILD_DIR.join("manageiq")
      end

      def build_file
        Dir.chdir(miq_dir) do
          git_sha = `git rev-parse --short HEAD`
          build   = "#{BUILD_DATE}_#{git_sha}"
          File.write("BUILD", build)
        end
      end

      def release_file
        File.write(miq_dir.join("RELEASE"), RELEASE)
      end

      def precompile_assets
        Dir.chdir(miq_dir) do
          shell_cmd("RAILS_ENV=production bundle exec rake evm:compile_assets")
        end
      end

      def precompile_sti_loader
        Dir.chdir(miq_dir) do
          shell_cmd("bundle exec rake evm:compile_sti_loader")
        end
      end

      def build_service_ui
        Dir.chdir(BUILD_DIR.join("manageiq-ui-service")) do
          shell_cmd("yarn install")
          shell_cmd("yarn run available-languages")
          shell_cmd("yarn run build")
          shell_cmd("git clean -xdf")  # cleanup temp files
        end
      end

      def seed_ansible_runner
        Dir.chdir(miq_dir) do
          shell_cmd("bundle exec rake evm:ansible_runner:seed")
        end
      end

      def populate
        rake_path = `which rake`.chomp
        gem_home_rake = GEM_HOME.join("bin/rake").to_s
        raise "Error: #{gem_home_rake} should be used, but #{rake_path} is being used instead." unless rake_path == gem_home_rake

        build_file
        release_file
        precompile_assets
        precompile_sti_loader
        build_service_ui
        seed_ansible_runner

        if ENV["NPM_REGISTRY_OVERRIDE"]
          Dir.chdir(BUILD_DIR.join("manageiq")) { system_cmd("#{SCRIPT_DIR.join("scripts/npm_registry/yarn_registry_cleanup.sh")}") }
        end
      end
    end
  end
end
