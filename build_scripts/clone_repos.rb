require 'fileutils'
require 'pathname'
require 'yaml'

class SourceRepos
  attr_reader :build_dir, :rpm_spec_dir, :git_tag, :github_url, :product_name

  def initialize
    puts "\n---> #{self.class.name}::#{__method__}"
    options = YAML.load_file("config/options.yml")

    @build_dir    = Pathname.new(options["build_dir"]).expand_path
    @rpm_spec_dir = build_dir.join("rpm_spec")
    @git_tag      = options["git_tag"]
    @github_url   = options["github_url"]
    @product_name = options["product_name"]
  end

  def populate
    puts "\n---> #{self.class.name}::#{__method__}"
    clean_build_dir
    setup_rpm_spec_repo
    setup_source_repo
    FileUtils.cp(Pathname.new(__dir__).join("evm_productization"), build_dir.join("manageiq-appliance/LINK/etc/default/"))
  end

  def clean_build_dir
    puts "\n---> #{self.class.name}::#{__method__} build_dir ->#{build_dir}<-}"
    FileUtils.rm_rf build_dir
    FileUtils.mkdir_p build_dir
  end

  def setup_rpm_spec_repo
    FileUtils.mkdir_p rpm_spec_dir
    FileUtils.cp_r("/build_scripts/rpm_spec", build_dir)
    Dir.chdir(rpm_spec_dir) do
      #git_clone("#{github_url}/#{product_name}-gemset.git")
      #git_clone("#{github_url}/#{product_name}.git")
      #git_clone("#{github_url}/#{product_name}-appliance.git")
   end
  end

  def setup_source_repo
    puts "\n---> #{self.class.name}::#{__method__}"

    Dir.chdir(build_dir) do
      git_clone("#{github_url}/#{product_name}-appliance-build.git", "manageiq-appliance-build")
      git_clone("#{github_url}/#{product_name}-appliance.git", "manageiq-appliance")
      git_clone("#{github_url}/#{product_name}.git", "manageiq")
      git_clone("#{github_url}/#{product_name}-ui-service.git", "manageiq-ui-service")
    end
  end

  private

  def git_clone(repo_url, destination = nil)
    destination ||= File.basename(repo_url, ".git")
    exit $?.exitstatus unless system("git clone --depth 1 -b #{git_tag} #{repo_url} #{destination}")
  end
end
