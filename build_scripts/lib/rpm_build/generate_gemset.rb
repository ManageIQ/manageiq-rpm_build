require 'awesome_spawn'
require 'fileutils'
require 'pathname'
require 'pp'
require 'rake'
require 'rake/testtask'
require 'rubygems'
require 'yaml'
require_relative 'manageiq_tar_build'

def shell_cmd(cmd)
  puts "\n\t#{cmd}"
  exit $?.exitstatus unless system(cmd)
end

class GemSet
  attr_reader :build_dir, :rpm_spec_dir, :gem_home, :version, :current_env, :bundler_version,
              :product_name, :script_dir

  def initialize(options)
    puts "\n---> #{self.class.name}::#{__method__}"

    # Could be set in YAML config file or superseded with an ENV variable
    # Where requiring updates to the YAML config file is not always necessary.
    @version          = ENV["VERSION"] || options["version"]
    @build_dir        = Pathname.new(options["build_dir"]).expand_path
    @bundler_version  = options["bundler_version"]
    @product_name     = options["product_name"]

    # Derived
    @gem_home         = build_dir.join("#{product_name}-gemset-#{version}")
    @rpm_spec_dir     = build_dir.join("rpm_spec")

    @script_dir       = Pathname.new(__dir__)
  end

  def backup_environment_variables
    puts "\n---> #{self.class.name}::#{__method__}"
    @current_env = { "GEM_HOME" => ENV["GEM_HOME"], "GEM_PATH" => ENV["GEM_PATH"], "PATH" => ENV["PATH"] }
  end

  def set_environment_variables
    puts "\n---> #{self.class.name}::#{__method__}"

    ENV["APPLIANCE"] = "true"
    ENV["RAILS_USE_MEMORY_STORE"] = "true"
    ENV["GEM_HOME"]  = nil
    ENV["GEM_PATH"]  = nil
    ENV["PATH"]      = "/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/root/bin:~/bin"

    ENV["GEM_HOME"] = gem_home.to_s
    ENV["GEM_PATH"] = "#{gem_home}:/usr/share/gems:/usr/local/share/gems"
    ENV["PATH"]     = "#{gem_home}/bin:#{ENV["PATH"]}"

    shell_cmd("gem env")
    shell_cmd("echo -e \"${PATH}\\n\"")
  end

  def restore_environment_variables
    puts "\n---> #{self.class.name}::#{__method__}"
    current_env.each do |env_key, env_value|
      ENV[env_key] = env_value
    end
  end

  def recreate_gem_home
    FileUtils.rm_rf(gem_home) if File.directory?(gem_home)
    FileUtils.mkdir(gem_home)
    cmd = "gem install bundler"
    cmd << " -v #{bundler_version}" if bundler_version
    shell_cmd(cmd)
  end

  def populate_gem_home
    puts "\n---> #{self.class.name}::#{__method__}"

    Dir.chdir(build_dir.join("manageiq")) do
      FileUtils.ln_s(build_dir.join("manageiq-appliance/manageiq-appliance-dependencies.rb"),
                     "bundler.d/manageiq-appliance-dependencies.rb", :force => true)

      shell_cmd("gem env")
      shell_cmd("gem install mime-types -v 2.6.1")
      shell_cmd("bundle _#{bundler_version}_ install --with qpid_proton --without test:development:metric_fu --jobs 3 --retry 3")

      # Copy libsodium.so* to where rbnacl-libsodium expects
      rbnacl_libsodium_gem_dir = Pathname.new(`bundle info --path rbnacl-libsodium`.chomp)
      libsodium_library_dir    = "#{rbnacl_libsodium_gem_dir}/vendor/libsodium/dist/lib"
      FileUtils.mkdir_p(libsodium_library_dir)
      FileUtils.cp(Dir[rbnacl_libsodium_gem_dir.join("tmp/x86_64-linux/stage/vendor/libsodium/dist/lib/libsodium.so*")], libsodium_library_dir)

      # https://github.com/ManageIQ/manageiq/pull/17886
      FileUtils.mkdir("log") unless Dir.exists?("log")

      if ENV["NPM_REGISTRY_OVERRIDE"]
        shell_cmd("#{script_dir.join("npm_registry/yarn_registry_setup.sh")}")
      end

      shell_cmd("rake update:ui")

      # Add .bundle, bin, manifest and Gemfile.lock to the gemset
      FileUtils.mkdir_p(gem_home.join("vmdb/.bundle"))
      FileUtils.mkdir_p(gem_home.join("vmdb/bin"))
      FileUtils.cp(build_dir.join("manageiq/.bundle/config"), gem_home.join("vmdb/.bundle"))
      FileUtils.cp_r(build_dir.join("manageiq/.bundle/plugin"), gem_home.join("vmdb/.bundle/"))
      FileUtils.cp(build_dir.join("manageiq/Gemfile.lock"), gem_home.join("vmdb"))
      shell_cmd("bundle list > #{gem_home}/vmdb/manifest")
      FileUtils.cp(Dir[build_dir.join("manageiq/bin/*")], gem_home.join("vmdb/bin"))

      link_git_gems
    end
  end

  def scrub
    puts "\n---> #{self.class.name}::#{__method__}"
    cleanse_gemset
  end

  private

  def cleanse_gemset
    puts "\n---> #{self.class.name}::#{__method__}"

    # Remove unneeded files
    Dir.chdir(gem_home) do
      FileUtils.rm_rf(Dir.glob("bundler/gems/*/.git"))
      FileUtils.rm_rf(Dir.glob("cache/*"))
      shell_cmd("#{script_dir.join("gem_cleanup.sh")}")
    end
  end

  def link_git_gems
    puts "\n---> #{self.class.name}::#{__method__}"

    Dir.chdir(build_dir.join("manageiq")) do
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

class MakeTarFile
  attr_reader :build_dir, :rpm_spec_dir, :version, :gem_home, :product_name, :cfg_dir, :script_dir

  def initialize(options)
    puts "\n---> #{self.class.name}::#{__method__}"

    # Could be set in YAML config file or superseded with an ENV variable
    # Where requiring updates to the YAML config file is not always necessary.
    @version           = ENV["VERSION"] || options["version"]
    @build_dir         = Pathname.new(options["build_dir"]).expand_path
    @product_name      = options["product_name"]

    @script_dir        = Pathname.new(__dir__)
    @cfg_dir           = script_dir.join("config")

    # Derived
    @gem_home          = build_dir.join("#{product_name}-gemset-#{version}")
    @rpm_spec_dir      = build_dir.join("rpm_spec")
  end

  def create_gemset_tarball
    puts "\n---> #{self.class.name}::#{__method__}"
    Dir.chdir(build_dir) do
      gemset_public_dir = gem_home.join("vmdb/public")
      FileUtils.mkdir_p(gemset_public_dir)
      # Can't be symlink, as files need to be tar'ed without '-h' to keep symlink for git based gems
      FileUtils.cp_r(build_dir.join("manageiq/public/assets"), gemset_public_dir)
      FileUtils.cp_r(build_dir.join("manageiq/public/packs"), gemset_public_dir)

      # Override path in bundler plugin index
      plugin_index = gem_home.join("vmdb/.bundle/plugin/index")
      plugin_index.write(plugin_index.read.gsub(build_dir.join("manageiq").to_s, '/var/www/miq/vmdb'))

      shell_cmd("tar -zcf #{product_name}-gemset-#{version}.tar.gz #{product_name}-gemset-#{version}/")
    end
    FileUtils.cp(build_dir.join("#{product_name}-gemset-#{version}.tar.gz"), rpm_spec_dir.join("#{product_name}-gemset"))
  end

  def create_appliance_tarball
    puts "\n---> #{self.class.name}::#{__method__}"
    Dir.chdir(build_dir) do
      transform = "--transform s',\^,#{product_name}-appliance-#{version}\/,\'"
      base_dir = build_dir.join("manageiq-appliance")
      shell_cmd("tar -C #{base_dir} #{transform} --exclude='.git' -hzcf #{product_name}-appliance-#{version}.tar.gz .")

      FileUtils.cp(build_dir.join("#{product_name}-appliance-#{version}.tar.gz"), rpm_spec_dir.join("#{product_name}-appliance"))
    end
  end

  def create_manageiq_tarball
    puts "\n---> #{self.class.name}::#{__method__}"

    rake_path = `which rake`.chomp
    gem_home_rake = gem_home.join("bin/rake").to_s
    raise "Error: #{gem_home_rake} should be used, but #{rake_path} is being used instead." unless rake_path == gem_home_rake

    tar_build = ManageIQTarBuild.new(build_dir)
    tar_build.tar_prep

    if ENV["NPM_REGISTRY_OVERRIDE"]
      Dir.chdir(build_dir.join("manageiq")) { shell_cmd("#{script_dir.join("npm_registry/yarn_registry_cleanup.sh")}") }
    end

    tar_build.tar

    FileUtils.cp(build_dir.join("manageiq-appliance-build/pkg/#{product_name}-#{version}.tar.gz"), rpm_spec_dir.join(product_name))
  end
end

class TarBuild
  attr_reader :options

  def initialize
    puts "\n---> #{self.class.name}::#{__method__}"
    @options = YAML.load_file("config/options.yml")
  end

  def run
    puts "\n---> #{self.class.name}::#{__method__}"

    gemset = GemSet.new(options)
    gemset.backup_environment_variables
    gemset.set_environment_variables
    pp gemset
    gemset.recreate_gem_home
    gemset.populate_gem_home

    make_tar_file = MakeTarFile.new(options)
    make_tar_file.create_manageiq_tarball

    # Scrub the gemset only after it is used to generate the tarfile.
    gemset.scrub
    gemset.restore_environment_variables

    make_tar_file.create_gemset_tarball

    make_tar_file.create_appliance_tarball

    puts "\n\nTARBALL BUILT SUCCESSFULLY"
  end
end
