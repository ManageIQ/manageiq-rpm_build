require 'fileutils'
require 'pathname'
require 'manageiq/rpm_build/generate_core'

module ManageIQ
  module RPMBuild
    class GenerateTarFiles
      include Helper

      def create_gemset_tarball
        where_am_i

        tar_basename = "#{PRODUCT_NAME}-gemset-#{VERSION}"
        tar_name = RPM_SPEC_DIR.join("#{tar_basename}.tar.gz")

        # Override path in bundler plugin index
        plugin_index = GEM_HOME.join("vmdb/.bundle/plugin/index")
        plugin_index.write(plugin_index.read.gsub(BUILD_DIR.join("manageiq").to_s, '/var/www/miq/vmdb'))

        shell_cmd("tar -C #{BUILD_DIR} -zcf #{tar_name} #{tar_basename}")
      end

      def create_appliance_tarball
        where_am_i

        tar_basename = "#{PRODUCT_NAME}-appliance-#{VERSION}"
        tar_name  = RPM_SPEC_DIR.join("#{tar_basename}.tar.gz")
        transform = "--transform s',\^,#{tar_basename}\/,\'"

        shell_cmd("tar -C #{BUILD_DIR.join("manageiq-appliance")} #{transform} --exclude='.git' -hzcf #{tar_name} .")
      end

      def create_core_tarball
        where_am_i

        tar_basename = "#{PRODUCT_NAME}-core-#{VERSION}"
        tar_name = RPM_SPEC_DIR.join("#{tar_basename}.tar.gz")
        transform = "--transform s',\^,#{tar_basename}\/,\'"
        exclude_file = CONFIG_DIR.join("exclude_manageiq")

        # Everything from */tmp/* should be excluded, except for tmp/cache/sti_loader.yml
        shell_cmd("tar -C #{BUILD_DIR.join("manageiq")} #{transform} --exclude-tag='cache/sti_loader.yml' -X #{exclude_file} -hcvzf #{tar_name} .")
      end
    end
  end
end
