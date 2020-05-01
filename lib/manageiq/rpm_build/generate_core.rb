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

      def tar_prep
        build_file
        release_file
        precompile_assets
        precompile_sti_loader
        build_service_ui
        seed_ansible_runner
      end

      def tar
        exclude_file = CONFIG_DIR.join("exclude_manageiq")
        pkg_path     = BUILD_DIR.join("manageiq-appliance-build", "pkg")
        FileUtils.mkdir_p(pkg_path)

        tar_version = VERSION.split("-").first
        tar_basename = "#{PRODUCT_NAME}-#{tar_version}"
        tarball = pkg_path.join("#{tar_basename}.tar.gz")

        # Add a product_name-version directory to the top of the files added to the tar.
        # This is needed by rpm tooling.
        transform = RUBY_PLATFORM =~ /darwin/ ? "-s " : "--transform s"
        transform << "',^,#{tar_basename}/,'"

        # Everything from */tmp/* should be excluded, except for tmp/cache/sti_loader.yml
        shell_cmd("tar -C #{miq_dir} #{transform} --exclude-tag='cache/sti_loader.yml' -X #{exclude_file} -hcvzf #{tarball} .")
        puts "Built tarball at:\n #{File.expand_path(tarball)}"
      end
    end
  end
end
