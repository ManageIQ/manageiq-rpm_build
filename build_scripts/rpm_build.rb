require 'awesome_spawn'
require 'pathname'
require 'yaml'

class RpmBuild

  attr_reader :rpm_name, :rpm_spec_dir, :rpm_version, :rpm_release, :rpm_repo_name

  def initialize(name)
    @rpm_name = name

    options = YAML.load_file("config/options.yml")
    @rpm_spec_dir = Pathname.new(options["build_dir"]).expand_path.join("rpm_spec/#{name}")
    @rpm_version  = options["version"]

    build_date   = Time.now.strftime("%Y%m%d")
    @rpm_release = "1.#{build_date}"  # TODO: add SHA

    @rpm_repo_name = options["rpm_repo_name"]
  end

  def generate_rpm
    puts "\n---> #{self.class.name}::#{__method__}"
    spec_dir = rpm_spec_dir.join(rpm_name)

    Dir.chdir(rpm_spec_dir) do
      update_spec_version
      #TODO - need to allow customization
      exit $?.exitstatus unless system("rpmbuild -bs --define '_sourcedir .' --define '_srcrpmdir .' #{rpm_name}.spec")
      exit $?.exitstatus unless system("copr-cli --config /build_scripts/copr-cli-token build -r epel-8-x86_64 #{rpm_repo_name} #{rpm_name}-*.src.rpm")
    end
  end

  private

  def update_spec_version
    puts "\n---> #{self.class.name}::#{__method__}"

    spec_file = rpm_spec_dir.join("#{rpm_name}.spec")
    spec_text = File.read(spec_file)

    spec_text.sub!("RPM_VERSION", rpm_version)
    spec_text.sub!("RPM_RELEASE", rpm_release)
    File.write(spec_file, spec_text)
  end
end
