require 'fileutils'
require 'pathname'
require 'manageiq/rpm_build/generate_core'

module ManageIQ
  module RPMBuild
    class GenerateTarFiles
      include Helper

      def create_tarballs
        create_core_tarball
        create_gemset_tarball
        create_appliance_tarball
        create_ansible_venv_tarball
      end

      def create_gemset_tarball
        where_am_i

        # Override path in bundler plugin index
        plugin_index = GEM_HOME.join("vmdb/.bundle/plugin/index")
        plugin_index.write(plugin_index.read.gsub(BUILD_DIR.join("manageiq").to_s, '/var/www/miq/vmdb'))

        name = "gemset"
        shell_cmd("tar -C #{BUILD_DIR} -zcf #{tar_full_path(name)} --exclude-vcs -X #{exclude_file(name)} #{tar_basename(name)}")
      end

      def create_appliance_tarball
        where_am_i

        name = "appliance"
        shell_cmd("tar -C #{BUILD_DIR.join("manageiq-appliance")} #{transform(name)} --exclude-vcs -hzcf #{tar_full_path(name)} .")
      end

      def create_core_tarball
        where_am_i

        name = "core"

        # Everything from */tmp/* should be excluded, except for tmp/cache/sti_loader.yml
        shell_cmd("tar -C #{BUILD_DIR.join("manageiq")} #{transform(name)} --exclude-vcs --exclude-tag='cache/sti_loader.yml' -X #{exclude_file("manageiq")} -hczf #{tar_full_path(name)} .")
      end

      def create_ansible_venv_tarball
        where_am_i

        name = "ansible-venv"
        shell_cmd("tar -C #{BUILD_DIR.join("manageiq-ansible-venv")} #{transform(name)} --exclude-vcs -X #{exclude_file(name)} -hzcf #{tar_full_path(name)} .")
      end

      def create_manifest_tarball
        where_am_i

        name = "manifest"
        shell_cmd("tar -C #{BUILD_DIR.join(name)} #{transform(name)} --exclude-vcs -hzcf #{tar_full_path(name)} .")
      end

      private

      def exclude_file(tarball_name)
        CONFIG_DIR.join("exclude_#{tarball_name}")
      end

      def tar_basename(name)
        "#{OPTIONS.product_name}-#{name}-#{OPTIONS.rpm.version}"
      end

      def transform(name)
        "--transform s',\^,#{tar_basename(name)}\/,\'"
      end

      def tar_full_path(name)
        RPM_SPEC_DIR.join("#{tar_basename(name)}.tar.gz")
      end
    end
  end
end
