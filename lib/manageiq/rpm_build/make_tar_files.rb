require 'fileutils'
require 'pathname'
require_relative 'manageiq_tar_build'

module ManageIQ
  module RPMBuild
    class MakeTarFile
      attr_reader :gem_home

      def initialize
        puts "\n---> #{self.class.name}::#{__method__}"
        @gem_home  = BUILD_DIR.join("#{PRODUCT_NAME}-gemset-#{VERSION}")
      end

      def shell_cmd(cmd)
        puts "\n\t#{cmd}"
        exit $?.exitstatus unless system(cmd)
      end

      def create_gemset_tarball
        puts "\n---> #{self.class.name}::#{__method__}"
        Dir.chdir(BUILD_DIR) do
          gemset_public_dir = gem_home.join("vmdb/public")
          FileUtils.mkdir_p(gemset_public_dir)
          # Can't be symlink, as files need to be tar'ed without '-h' to keep symlink for git based gems
          FileUtils.cp_r(BUILD_DIR.join("manageiq/public/assets"), gemset_public_dir)
          FileUtils.cp_r(BUILD_DIR.join("manageiq/public/packs"), gemset_public_dir)

          # Override path in bundler plugin index
          plugin_index = gem_home.join("vmdb/.bundle/plugin/index")
          plugin_index.write(plugin_index.read.gsub(BUILD_DIR.join("manageiq").to_s, '/var/www/miq/vmdb'))

          shell_cmd("tar -zcf #{PRODUCT_NAME}-gemset-#{VERSION}.tar.gz #{PRODUCT_NAME}-gemset-#{VERSION}/")
        end
        FileUtils.cp(BUILD_DIR.join("#{PRODUCT_NAME}-gemset-#{VERSION}.tar.gz"), RPM_SPEC_DIR.join("#{PRODUCT_NAME}-gemset"))
      end

      def create_appliance_tarball
        puts "\n---> #{self.class.name}::#{__method__}"
        Dir.chdir(BUILD_DIR) do
          transform = "--transform s',\^,#{PRODUCT_NAME}-appliance-#{VERSION}\/,\'"
          base_dir = BUILD_DIR.join("manageiq-appliance")
          shell_cmd("tar -C #{base_dir} #{transform} --exclude='.git' -hzcf #{PRODUCT_NAME}-appliance-#{VERSION}.tar.gz .")

          FileUtils.cp(BUILD_DIR.join("#{PRODUCT_NAME}-appliance-#{VERSION}.tar.gz"), RPM_SPEC_DIR.join("#{PRODUCT_NAME}-appliance"))
        end
      end

      def create_manageiq_tarball
        puts "\n---> #{self.class.name}::#{__method__}"

        rake_path = `which rake`.chomp
        gem_home_rake = gem_home.join("bin/rake").to_s
        raise "Error: #{gem_home_rake} should be used, but #{rake_path} is being used instead." unless rake_path == gem_home_rake

        tar_build = ManageIQTarBuild.new
        tar_build.tar_prep

        if ENV["NPM_REGISTRY_OVERRIDE"]
          Dir.chdir(BUILD_DIR.join("manageiq")) { shell_cmd("#{SCRIPT_DIR.join("scripts/npm_registry/yarn_registry_cleanup.sh")}") }
        end

        tar_build.tar

        FileUtils.cp(BUILD_DIR.join("manageiq-appliance-build/pkg/#{PRODUCT_NAME}-#{VERSION}.tar.gz"), RPM_SPEC_DIR.join(PRODUCT_NAME))
      end
    end
  end
end