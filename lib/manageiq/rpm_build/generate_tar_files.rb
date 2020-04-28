require 'fileutils'
require 'pathname'
require 'manageiq/rpm_build/generate_core'

module ManageIQ
  module RPMBuild
    class GenerateTarFiles
      include Helper

      def create_gemset_tarball
        where_am_i
        Dir.chdir(BUILD_DIR) do
          # Override path in bundler plugin index
          plugin_index = GEM_HOME.join("vmdb/.bundle/plugin/index")
          plugin_index.write(plugin_index.read.gsub(BUILD_DIR.join("manageiq").to_s, '/var/www/miq/vmdb'))

          shell_cmd("tar -zcf #{PRODUCT_NAME}-gemset-#{VERSION}.tar.gz #{PRODUCT_NAME}-gemset-#{VERSION}/")
        end
        FileUtils.cp(BUILD_DIR.join("#{PRODUCT_NAME}-gemset-#{VERSION}.tar.gz"), RPM_SPEC_DIR.join("#{PRODUCT_NAME}-gemset"))
      end

      def create_appliance_tarball
        where_am_i
        Dir.chdir(BUILD_DIR) do
          transform = "--transform s',\^,#{PRODUCT_NAME}-appliance-#{VERSION}\/,\'"
          base_dir = BUILD_DIR.join("manageiq-appliance")
          shell_cmd("tar -C #{base_dir} #{transform} --exclude='.git' -hzcf #{PRODUCT_NAME}-appliance-#{VERSION}.tar.gz .")

          FileUtils.cp(BUILD_DIR.join("#{PRODUCT_NAME}-appliance-#{VERSION}.tar.gz"), RPM_SPEC_DIR.join("#{PRODUCT_NAME}-appliance"))
        end
      end

      def create_manageiq_tarball
        where_am_i

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
        shell_cmd("tar -C #{BUILD_DIR.join("manageiq")} #{transform} --exclude-tag='cache/sti_loader.yml' -X #{exclude_file} -hcvzf #{tarball} .")
        puts "Built tarball at:\n #{File.expand_path(tarball)}"

        FileUtils.cp(BUILD_DIR.join("manageiq-appliance-build/pkg/#{PRODUCT_NAME}-#{VERSION}.tar.gz"), RPM_SPEC_DIR.join(PRODUCT_NAME))
      end
    end
  end
end
