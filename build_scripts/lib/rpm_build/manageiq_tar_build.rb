require 'pathname'
require 'yaml'

class ManageIQTarBuild
  attr_reader :app_dir, :cfg_dir, :miq_dir, :options

  def initialize(app_dir)
    @app_dir      = app_dir
    @cfg_dir      = Pathname.new(__dir__).join("config")
    @miq_dir      = app_dir.join("manageiq")

    @options = YAML.load_file(cfg_dir.join("options.yml"))
  end

  def version
    @version ||= options["version"] || File.read(miq_dir.join("VERSION")).chomp
  end

  def release
    @release ||= options["release"]
  end

  def prefix
    @prefix ||= options["product_name"]
  end

  def system_cmd(cmd)
    puts "Running: #{cmd}"
    exit $?.exitstatus unless system(cmd)
  end

  def build_file
    date    = Time.now.strftime("%Y%m%d%H%M%S")
    Dir.chdir(miq_dir) do
      git_sha = `git rev-parse --short HEAD`
      build   = "#{version}-#{date}_#{git_sha}"
      File.write("BUILD", build)
    end
  end

  def version_file
    File.write(miq_dir.join("VERSION"), version)
  end

  def release_file
    File.write(miq_dir.join("RELEASE"), release)
  end

  def precompile_assets
    Dir.chdir(miq_dir) do
      system_cmd("RAILS_ENV=production bundle exec rake evm:compile_assets")
    end
  end

  def precompile_sti_loader
    Dir.chdir(miq_dir) do
      system_cmd("bundle exec rake evm:compile_sti_loader")
    end
  end

  def build_service_ui
    Dir.chdir(app_dir.join("manageiq-ui-service")) do
      system_cmd("yarn install")
      system_cmd("yarn run available-languages")
      system_cmd("yarn run build")
      system_cmd("git clean -xdf")  # cleanup temp files
    end
  end

  def seed_ansible_runner
    Dir.chdir(miq_dir) do
      system_cmd("bundle exec rake evm:ansible_runner:seed")
    end
  end

  def tar_prep
    version_file
    build_file
    release_file
    precompile_assets
    precompile_sti_loader
    build_service_ui
    seed_ansible_runner
  end

  def tar
    exclude_file = cfg_dir.join("exclude_manageiq")
    pkg_path     = app_dir.join("manageiq-appliance-build", "pkg")
    FileUtils.mkdir_p(pkg_path)

    tar_version = version.split("-").first
    tar_basename = "#{prefix}-#{tar_version}"
    tarball = pkg_path.join("#{tar_basename}.tar.gz")

    # Add a prefix-version directory to the top of the files added to the tar.
    # This is needed by rpm tooling.
    transform = RUBY_PLATFORM =~ /darwin/ ? "-s " : "--transform s"
    transform << "',^,#{tar_basename}/,'"

    # Everything from */tmp/* should be excluded, except for tmp/cache/sti_loader.yml
    system_cmd("tar -C #{miq_dir} #{transform} --exclude-tag='cache/sti_loader.yml' -X #{exclude_file} -hcvzf #{tarball} .")
    puts "Built tarball at:\n #{File.expand_path(tarball)}"
  end
end
