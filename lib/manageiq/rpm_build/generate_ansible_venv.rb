require 'fileutils'

module ManageIQ
  module RPMBuild
    class GenerateAnsibleVenv
      include Helper

      VENV_PYTHON_VERSION = "3.12".freeze

      attr_reader :current_env, :manifest_dir, :venv_dir

      def initialize
        where_am_i

        @manifest_dir = MANIFEST_DIR
        @venv_dir     = BUILD_DIR.join("manageiq-ansible-venv")

        # Unlike the other generators that build within BUILD_DIR, we need to
        # build the venv in the target path because virtualenv uses the fully
        # qualified path in things like shebangs for the bin files.
        @venv_build_dir  = Pathname.new("/var/lib/manageiq")
        @venv_build_path = @venv_build_dir.join("venv")
      end

      def populate
        where_am_i

        FileUtils.rm_rf(@venv_build_dir)
        FileUtils.mkdir_p(@venv_build_dir)
        Dir.chdir(@venv_build_dir) do
          install_python_system_packages

          create_venv
          install_venv_packages
          generate_manifest
          scrub

          move_content_to_build_dir
        end
      end

      private

      # Install the same system packages as we will have at build time, so that
      # virtualenv's --system-site-packages flag works as expected.
      def install_python_system_packages
        where_am_i

        shell_cmd("#{pip_versioned} install --no-compile ansible-runner")
      end

      def create_venv
        where_am_i

        shell_cmd("virtualenv --system-site-packages #{@venv_build_path}")
      end

      def install_venv_packages
        where_am_i

        shell_cmd_in_venv("#{pip_versioned} install --no-compile -r #{CONFIG_DIR.join("requirements.txt")}", @venv_build_path)
      end

      def generate_manifest
        where_am_i

        shell_cmd_in_venv("#{pip_versioned} install pip-licenses", @venv_build_path)
        shell_cmd_in_venv("pip-licenses --from=mixed --format=csv --output-file=#{@venv_build_dir.join("ansible_venv_manifest.csv")}", @venv_build_path)
        # TODO: Detect which packages were installed by pip-licenses so we can subsequently remove them
        shell_cmd_in_venv("#{pip_versioned} uninstall -y pip-licenses prettytable wcwidth", @venv_build_path)
      end

      def scrub
        where_am_i

        # Remove unneeded files
        Dir.chdir(@venv_build_path) do
          FileUtils.rm_rf(Dir.glob("share/doc/*"))
        end
      end

      def move_content_to_build_dir
        where_am_i

        FileUtils.rm_rf(venv_dir)

        # Copy the venv dir
        FileUtils.mv(@venv_build_dir, venv_dir)

        # Copy python site-packages for ansible-runner
        site_packages_dir = venv_dir.join("site-packages")
        FileUtils.mkdir_p(site_packages_dir)
        dirs_to_copy = Dir.glob("/usr/local/lib/python#{VENV_PYTHON_VERSION}/site-packages/*")
        FileUtils.cp_r(dirs_to_copy, site_packages_dir)

        # Copy ansible-runner bin file
        FileUtils.cp("/usr/local/bin/ansible-runner", venv_dir)
      end

      def pip_versioned
        "pip#{VENV_PYTHON_VERSION}"
      end
    end
  end
end
