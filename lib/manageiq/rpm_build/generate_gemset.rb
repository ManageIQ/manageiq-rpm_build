require 'awesome_spawn'
require 'fileutils'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class GenerateGemSet
      include Helper

      attr_reader :current_env, :bundler_version

      def initialize
        where_am_i

        options = YAML.load_file(CONFIG_DIR.join("options.yml"))
        @bundler_version  = options["bundler_version"]
      end

      def backup_environment_variables
        where_am_i
        @current_env = { "GEM_HOME" => ENV["GEM_HOME"], "GEM_PATH" => ENV["GEM_PATH"], "PATH" => ENV["PATH"] }
      end

      def set_environment_variables
        where_am_i

        ENV["APPLIANCE"] = "true"
        ENV["RAILS_USE_MEMORY_STORE"] = "true"
        ENV["GEM_HOME"]  = nil
        ENV["GEM_PATH"]  = nil
        ENV["PATH"]      = "/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/root/bin:~/bin"

        ENV["GEM_HOME"] = GEM_HOME.to_s
        ENV["GEM_PATH"] = "#{GEM_HOME}:/usr/share/gems:/usr/local/share/gems"
        ENV["PATH"]     = "#{GEM_HOME}/bin:#{ENV["PATH"]}"

        shell_cmd("gem env")
        shell_cmd("echo -e \"${PATH}\\n\"")
      end

      def restore_environment_variables
        where_am_i
        current_env.each do |env_key, env_value|
          ENV[env_key] = env_value
        end
      end

      def recreate_gem_home
        FileUtils.rm_rf(GEM_HOME) if GEM_HOME.exist?
        FileUtils.mkdir(GEM_HOME)
        cmd = "gem install bundler"
        cmd << " -v #{bundler_version}" if bundler_version
        shell_cmd(cmd)
      end

      def populate_gem_home
        where_am_i

        Dir.chdir(BUILD_DIR.join("manageiq")) do
          FileUtils.ln_s(BUILD_DIR.join("manageiq-appliance/manageiq-appliance-dependencies.rb"),
                         "bundler.d/manageiq-appliance-dependencies.rb", :force => true)

          shell_cmd("gem env")
          shell_cmd("gem install mime-types -v 2.6.1")
          shell_cmd("bundle _#{bundler_version}_ install --with qpid_proton --without test:development:metric_fu --jobs #{cpus} --retry 3")

          # Copy libsodium.so* to where rbnacl-libsodium expects
          rbnacl_libsodium_gem_dir = Pathname.new(`bundle info --path rbnacl-libsodium`.chomp)
          libsodium_library_dir    = "#{rbnacl_libsodium_gem_dir}/vendor/libsodium/dist/lib"
          FileUtils.mkdir_p(libsodium_library_dir)
          FileUtils.cp(Dir[rbnacl_libsodium_gem_dir.join("tmp/x86_64-linux/stage/vendor/libsodium/dist/lib/libsodium.so*")], libsodium_library_dir)

          # https://github.com/ManageIQ/manageiq/pull/17886
          FileUtils.mkdir("log") unless Dir.exists?("log")

          if ENV["NPM_REGISTRY_OVERRIDE"]
            shell_cmd("#{SCRIPT_DIR.join("scripts/npm_registry/yarn_registry_setup.sh")}")
          end

          shell_cmd("rake update:ui")

          # Add .bundle, bin, manifest and Gemfile.lock to the gemset
          FileUtils.mkdir_p(GEM_HOME.join("vmdb/.bundle"))
          FileUtils.mkdir_p(GEM_HOME.join("vmdb/bin"))
          FileUtils.cp(BUILD_DIR.join("manageiq/.bundle/config"), GEM_HOME.join("vmdb/.bundle"))
          FileUtils.cp_r(BUILD_DIR.join("manageiq/.bundle/plugin"), GEM_HOME.join("vmdb/.bundle/"))
          FileUtils.cp(BUILD_DIR.join("manageiq/Gemfile.lock"), GEM_HOME.join("vmdb"))
          shell_cmd("bundle list > #{GEM_HOME}/vmdb/manifest")
          FileUtils.cp(Dir[BUILD_DIR.join("manageiq/bin/*")], GEM_HOME.join("vmdb/bin"))

          link_git_gems
        end
      end

      def scrub
        where_am_i
        cleanse_gemset
      end

      private

      def cpus
        c = `nproc --all` rescue nil
        c = c.to_i
        c == 0 ? 3 : c
      end

      def cleanse_gemset
        where_am_i

        # Remove unneeded files
        Dir.chdir(GEM_HOME) do
          FileUtils.rm_rf(Dir.glob("bundler/gems/*/.git"))
          FileUtils.rm_rf(Dir.glob("cache/*"))
          shell_cmd("#{SCRIPT_DIR.join("scripts/gem_cleanup.sh")}")
        end
      end

      def link_git_gems
        where_am_i

        Dir.chdir(BUILD_DIR.join("manageiq")) do
          # This command searches for the git based gems in GEM_HOME/bundler/gems and creates
          # symlinks for each replacing the git-sha with the gem version.
          # TODO: Refactor using Bundler and Gem class directly
          cmd = "ruby -e \'require \"bundler/setup\"; "
          cmd << "Gem.loaded_specs.values.select { |s| s.full_gem_path.include?(\"bundler/gems\") }.each "
          cmd << "{|t| path = Pathname.new(t.full_gem_path).relative_path_from(Pathname.new(ENV[\"GEM_HOME\"])); "
          cmd << "puts "
          cmd << "\"../\#\{path\}/\#\{t.name\}.gemspec \#\{ENV[\"GEM_HOME\"]}/specifications/\#\{t.full_name\}.gemspec\"; "
          cmd << "puts \"../\#\{path\} \#\{ENV[\"GEM_HOME\"]}/gems/\#\{t.full_name\}\"}\'"

          AwesomeSpawn.run!(cmd).output.split(/\n/).collect { |n| n.split(" ") }.each do |n|
            FileUtils.ln_s(n[0], n[1], :force => true)
          end
          shell_cmd("find \"$GEM_HOME/specifications\" -type l -xtype l -delete")
        end
      end
    end
  end
end
