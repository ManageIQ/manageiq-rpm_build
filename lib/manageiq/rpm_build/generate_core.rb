require 'json'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class GenerateCore
      include Helper

      attr_reader :miq_dir, :ui_service_dir

      def initialize
        @miq_dir = BUILD_DIR.join("manageiq")
        @ui_service_dir = BUILD_DIR.join("manageiq-ui-service")
      end

      def build_file
        Dir.chdir(miq_dir) do
          git_sha = `git rev-parse --short HEAD`
          build   = "#{BUILD_DATE}_#{git_sha}"
          File.write("BUILD", build)
        end
      end

      def version_file
        File.write(miq_dir.join("VERSION"), OPTIONS.version) if OPTIONS.version
      end

      def release_file
        File.write(miq_dir.join("RELEASE"), OPTIONS.release) if OPTIONS.release
      end

      def link_plugin_public_dirs
        symlink_plugin_paths("public", miq_dir.join("public"))
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
        symlink_plugin_paths("manageiq-ui-service", ui_service_dir)

        Dir.chdir(ui_service_dir) do
          if RUBY_PLATFORM.match?(/powerpc64le/)
            shell_cmd("npm config --global set python /usr/bin/python2.7")
          end
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
        version_file
        release_file
        link_plugin_public_dirs
        precompile_assets
        precompile_sti_loader
        build_service_ui
        seed_ansible_runner

        if OPTIONS.npm_registry
          Dir.chdir(miq_dir) do
            shell_cmd("#{SCRIPT_DIR.join("npm_registry/yarn_registry_cleanup.sh")} #{OPTIONS.npm_registry}")
          end
        end
      end

      private

      def plugin_paths
        @plugin_paths ||= Dir.chdir(miq_dir) do
          JSON.parse(`bundle exec rake evm:plugins:list[json]`)
            .map { |p| Pathname.new(p["path"]) }
            .select(&:exist?)
        end
      end

      def symlink_plugin_paths(source_dir, target_path)
        plugin_paths.each do |path|
          path = path.join(source_dir)
          next unless path.exist?

          path.children(false).each do |subdir|
            FileUtils.ln_s(path.join(subdir), target_path.join(subdir))
          end
        end
      end
    end
  end
end
