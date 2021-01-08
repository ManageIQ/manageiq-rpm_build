desc "Release a new project version"
task :release do
  require 'active_support/core_ext'
  require 'more_core_extensions/core_ext/hash/nested'
  require 'pathname'
  require 'yaml'

  version = ENV["RELEASE_VERSION"]

  if version.blank?
    STDERR.puts "ERROR: You must set the env var RELEASE_VERSION to the proper value."
    exit 1
  end

  if `git rev-parse --abbrev-ref HEAD`.chomp == "master"
    STDERR.puts "ERROR: You cannot cut a release from the master branch."
    exit 1
  end

  branch, minor_patch, milestone = version.split("-")
  major = (branch[0].ord - 96).to_s     # ivanchuk = 9, jansa = 10
  minor_patch << ".0" unless minor_patch.include?(".")
  new_version = "#{major}.#{minor_patch}"

  root = Pathname.new(__dir__)

  # Update rpm version and release
  options = root.join("config", "options.yml")
  content = YAML.load_file(options)
  current_release = content.fetch_path("rpm", "release")
  new_release = milestone ? (current_release + 0.1).round(1) : 1

  content.store_path("rpm", "version", new_version)
  content.store_path("rpm", "release", new_release)
  options.write(content.to_yaml)

  # Update changelog
  changelog = root.join("rpm_spec", "changelog")
  date = Time.now.strftime("%a %b %-d %Y")
  version_release = "#{new_version}-#{new_release}"
  version_release << ".#{milestone}" if milestone
  version_line = "* #{date} ManageIQ <contact@manageiq.org> - #{version_release}"
  text_line    = "- #{version.titleize} build"

  content = changelog.read
  content.sub!("%changelog", "%changelog\n#{version_line}\n#{text_line}\n")
  changelog.write(content)

  # Commit
  exit $?.exitstatus unless system("git add #{options} #{changelog}")
  exit $?.exitstatus unless system("git commit -m 'Release #{version}'")

  # Tag
  exit $?.exitstatus unless system("git tag #{version}")

  puts
  puts "The commit on #{branch} with the tag #{version} has been created"
  puts "Run the following to push to the upstream remote:"
  puts
  puts "\tgit push upstream #{branch} #{version}"
  puts
end
