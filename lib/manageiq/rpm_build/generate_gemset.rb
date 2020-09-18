require 'awesome_spawn'
require 'fileutils'
require 'pathname'
require 'yaml'

module ManageIQ
  module RPMBuild
    class GenerateGemSet
      include Helper

      attr_reader :current_env, :bundler_version, :manifest_dir, :miq_dir

      def initialize
        where_am_i
        @bundler_version = OPTIONS.bundler_version
        @manifest_dir    = BUILD_DIR.join("manifest")
        @miq_dir         = BUILD_DIR.join("manageiq")
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

      def populate_gem_home(build_type)
        where_am_i

        Dir.chdir(miq_dir) do
          FileUtils.ln_s(BUILD_DIR.join("manageiq-appliance/manageiq-appliance-dependencies.rb"),
                         "bundler.d/manageiq-appliance-dependencies.rb", :force => true)

          shell_cmd("gem env")
          shell_cmd("gem install mime-types -v 2.6.1")

          if RUBY_PLATFORM.match?(/powerpc64le/)
            shell_cmd("gem install sassc  -- --disable-march-tune-native")
            shell_cmd("gem install unf_ext -v '0.0.7.2' -- --with-cxxflags='-fsigned-char'")
          end

          shell_cmd("bundle config set --local with qpid_proton systemd")

          lock_release = miq_dir.join("Gemfile.lock.release")
          if lock_release.exist?
            FileUtils.ln_s(lock_release, "Gemfile.lock", :force => true)
            shell_cmd("bundle _#{bundler_version}_ lock --update --conservative --patch") if build_type == "nightly"
          end

          shell_cmd("bundle _#{bundler_version}_ install --jobs #{cpus} --retry 3")

          # Copy libsodium.so* to where rbnacl-libsodium expects
          # https://github.com/RubyCrypto/rbnacl-libsodium/issues/25
          rbnacl_libsodium_gem_dir = Pathname.new(`bundle info --path rbnacl-libsodium`.chomp)
          libsodium_library_dir    = "#{rbnacl_libsodium_gem_dir}/vendor/libsodium/dist/lib"
          FileUtils.mkdir_p(libsodium_library_dir)
          FileUtils.cp(Dir[rbnacl_libsodium_gem_dir.join("tmp/x86_64-linux/stage/vendor/libsodium/dist/lib/libsodium.so*")], libsodium_library_dir)

          # https://github.com/ManageIQ/manageiq/pull/17886
          FileUtils.mkdir("log") unless Dir.exists?("log")

          if OPTIONS.npm_registry
            shell_cmd("#{SCRIPT_DIR.join("npm_registry/yarn_registry_setup.sh")} #{OPTIONS.npm_registry}")
          end

          shell_cmd("rake update:ui")

          # Add .bundle, bin, manifest and Gemfile.lock to the gemset
          FileUtils.mkdir_p(GEM_HOME.join("vmdb/.bundle"))
          FileUtils.mkdir_p(GEM_HOME.join("vmdb/bin"))
          FileUtils.cp(miq_dir.join(".bundle/config"), GEM_HOME.join("vmdb/.bundle"))
          FileUtils.cp_r(miq_dir.join(".bundle/plugin"), GEM_HOME.join("vmdb/.bundle/"))
          FileUtils.cp(miq_dir.join("Gemfile.lock"), GEM_HOME.join("vmdb"))
          shell_cmd("bundle list > #{GEM_HOME}/vmdb/manifest")
          FileUtils.cp(Dir[miq_dir.join("bin/*")], GEM_HOME.join("vmdb/bin"))

          link_git_gems
        end
      end

      def scrub
        where_am_i
        cleanse_gemset
      end

      def generate_dependency_manifest
        where_am_i

        FileUtils.rm_rf(manifest_dir) if manifest_dir.exist?
        FileUtils.mkdir(manifest_dir)

        shell_cmd("gem install license_finder")
        generate_gem_manifest
        generate_npm_manifest
      end

      def generate_gem_manifest
        where_am_i
        run_license_finder(miq_dir, "gem")
      end

      def generate_npm_manifest
        where_am_i

        cmd = "rake update:print_engines | grep path: | cut -d: -f2"
        repos = AwesomeSpawn.run!(cmd, :chdir => miq_dir).output.split
        repos << BUILD_DIR.join("manageiq-ui-service")

        # license_finder tries to look for all supported package manager, move out Gemfile
        repo_with_gemfile = repos.select { |repo| File.exist?("#{repo}/Gemfile") }
        repo_with_gemfile.each { |repo| FileUtils.mv("#{repo}/Gemfile", "#{repo}/Gemfile.save") }
        run_license_finder(repos.join(" "), "npm")
        repo_with_gemfile.each { |repo| FileUtils.mv("#{repo}/Gemfile.save", "#{repo}/Gemfile") }
      end

      def run_license_finder(repos, type)
        where_am_i

        output  = manifest_dir.join("#{type}_manifest.csv")
        columns = "name version licenses"
        shell_cmd("BUNDLER_VERSION=#{bundler_version} license_finder report --format csv --write-headers --aggregate-paths #{repos} --columns #{columns} --save #{output}")
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

          # Vendored libgit2 isn't needed once the gem is compiled
          FileUtils.rm_rf(Dir.glob("gems/rugged-*/vendor"))

          # Vendored libsodium isn't needed once the gem is compiled
          # with execeptio of dist/lib/.so files which are not copied to extensions dir
          FileUtils.rm_rf(Dir.glob("gems/rbnacl-libsodium-*/vendor/libsodium/*").reject{|f| f.end_with?("/dist")})
          FileUtils.rm_rf(Dir.glob("gems/rbnacl-libsodium-*/tmp"))

          # Remove files with inappropriate license
          FileUtils.rm_rf(Dir.glob("gems/pdf-writer-*/demo")) # Creative Commons Attribution NonCommercial

          ["gems", "bundler/gems"].each do |path|
            FileUtils.rm_rf(Dir.glob("#{path}/**/*.o"))
            FileUtils.rm_rf(Dir.glob("#{path}/*/docs"))
            FileUtils.rm_rf(Dir.glob("#{path}/*/node_modules"))
            FileUtils.rm_rf(Dir.glob("#{path}/*/spec"))
            FileUtils.rm_rf(Dir.glob("#{path}/*/test"))
          end
        end
      end

      def link_git_gems
        where_am_i

        Dir.chdir(miq_dir) do
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
