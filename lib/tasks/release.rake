desc "Release a new project version"
task :release do
  require 'active_support'
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

namespace :release do
  desc "Tasks to run on a new branch when a new branch is created"
  task :new_branch do
    require 'pathname'

    branch = ENV["RELEASE_BRANCH"]
    if branch.nil? || branch.empty?
      STDERR.puts "ERROR: You must set the env var RELEASE_BRANCH to the proper value."
      exit 1
    end

    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp
    if current_branch == "master"
      STDERR.puts "ERROR: You cannot do new branch tasks from the master branch."
      exit 1
    end

    root = Pathname.new(__dir__).join("../..")

    branch_number = branch[0].ord - 96
    rpm_repo_name = "#{branch_number}-#{branch}"

    date     = Time.now.strftime("%a %b %-d %Y")
    username = `git config user.name`.chomp
    email    = `git config user.email`.chomp
    changelog_version = "* #{date} #{username} <#{email}> - #{branch_number}.0"
    changelog_text    = "- Initial build of manageiq-release for #{branch.capitalize}."

    # Modify Dockerfile
    dockerfile = root.join("Dockerfile")
    content = dockerfile.read
    content.sub!(%r{(rpm.manageiq.org/release/)\d+-\w+(/)}, "\\1#{rpm_repo_name}\\2")
    content.sub!(%r{(manageiq-release-)\d+}, "\\1#{branch_number}")
    dockerfile.write(content)

    # Modify options.yml
    options = root.join("config", "options.yml")
    content = options.read
    content.sub!(/^(repos:\n\s+ref:\s+).+$/, "\\1#{branch}")
    content.sub!(/^(rpm:\n\s+version:\s+).+$/, "\\1#{branch_number}.0.0")
    content.sub!(/^(\s{2}release:\s+).+$/, "\\10")
    options.write(content)

    # Rename files
    old_package = root.join("packages", "manageiq-release").glob("manageiq-*.repo").first
    new_package = root.join("packages", "manageiq-release", "manageiq-#{rpm_repo_name}.repo")
    FileUtils.mv(old_package, new_package) unless old_package == new_package

    # Modify manageiq-release repo
    content = new_package.read
    content.gsub!(/(\[manageiq-)\d+-\w+/, "\\1#{rpm_repo_name}")
    content.gsub!(/(name=ManageIQ )\d+ \(\w+\)/, "\\1#{branch_number} (#{branch.capitalize})")
    content.gsub!(%r{(rpm.manageiq.org/release/)\d+-\w+(/)}, "\\1#{rpm_repo_name}\\2")
    new_package.write(content)

    # Modify manageiq-release spec
    spec = root.join("packages", "manageiq-release", "manageiq-release.spec")
    content = spec.read
    content.sub!(/(Version:\s+)[\d.]+/, "\\1#{branch_number}.0")
    content.sub!(/(Release:\s+).+$/, "\\11\%{dist}")
    content.sub!(/(Source1:\s+manageiq-)\d+-\w+(\.repo)/, "\\1#{rpm_repo_name}\\2")
    unless content.include?(changelog_text)
      content.sub!("\%changelog", "\%changelog\n#{changelog_version}-1\%{dist}\n#{changelog_text}\n")
    end
    spec.write(content)

    # Commit
    files_to_update = [dockerfile, options, old_package, new_package, spec]
    exit $?.exitstatus unless system("git add #{files_to_update.join(" ")}")
    exit $?.exitstatus unless system("git commit -m 'Changes for new branch #{branch}'")

    puts
    puts "The commit on #{current_branch} has been created."
    puts "Run the following to push to the upstream remote:"
    puts
    puts "\tgit push upstream #{current_branch}"
    puts
  end

  desc "Tasks to run on the master branch when a new branch is created"
  task :new_branch_master do
    require 'pathname'

    branch = ENV["RELEASE_BRANCH"]
    if branch.nil? || branch.empty?
      STDERR.puts "ERROR: You must set the env var RELEASE_BRANCH to the proper value."
      exit 1
    end

    next_branch = ENV["RELEASE_BRANCH_NEXT"]
    if next_branch.nil? || next_branch.empty?
      STDERR.puts "ERROR: You must set the env var RELEASE_BRANCH_NEXT to the proper value."
      exit 1
    end

    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp
    if current_branch != "master"
      STDERR.puts "ERROR: You cannot do master branch tasks from a non-master branch (#{current_branch})."
      exit 1
    end

    root = Pathname.new(__dir__).join("../..")

    next_branch_number = next_branch[0].ord - 96
    rpm_repo_name = "#{next_branch_number}-#{next_branch}"

    date     = Time.now.strftime("%a %b %-d %Y")
    username = `git config user.name`.chomp
    email    = `git config user.email`.chomp
    changelog_version = "* #{date} #{username} <#{email}> - #{next_branch_number}.0"
    changelog_text    = "- Initial build of manageiq-release for #{next_branch.capitalize}."

    # Modify Dockerfile
    dockerfile = root.join("Dockerfile")
    content = dockerfile.read
    content.sub!(%r{(rpm.manageiq.org/release/)\d+-\w+(/)}, "\\1#{rpm_repo_name}\\2")
    content.sub!(%r{(manageiq-release-)\d+}, "\\1#{next_branch_number}")
    dockerfile.write(content)

    # Modify options.yml
    options = root.join("config", "options.yml")
    content = options.read
    content.sub!(/(rpm:\n\s+version:\s+).+/, "\\1#{next_branch_number}.0.0")
    content.sub!(/^(\s{2}release:\s+).+$/, "\\10")
    content.sub!(/^(\s{4}:)\d+\w+(:)/, "\\1#{rpm_repo_name}\\2")
    content.sub!(/^(\s{8}:manageiq:[^\d]+)\d+/, "\\1#{next_branch_number}")
    content.sub!(/^(\s{8}:manageiq-release:[^\d]+)\d+/, "\\1#{next_branch_number}")
    options.write(content)

    # Rename files
    old_package = root.join("packages", "manageiq-release").glob("manageiq-*.repo").first
    new_package = root.join("packages", "manageiq-release", "manageiq-#{rpm_repo_name}.repo")
    FileUtils.mv(old_package, new_package) unless old_package == new_package

    # Modify manageiq-release repo
    content = new_package.read
    content.gsub!(/(\[manageiq-)\d+-\w+/, "\\1#{rpm_repo_name}")
    content.gsub!(/(name=ManageIQ )\d+ \(\w+\)/, "\\1#{next_branch_number} (#{next_branch.capitalize})")
    content.gsub!(%r{(rpm.manageiq.org/release/)\d+-\w+(/)}, "\\1#{rpm_repo_name}\\2")
    new_package.write(content)

    # Modify manageiq-release spec
    spec = root.join("packages", "manageiq-release", "manageiq-release.spec")
    content = spec.read
    content.sub!(/(Version:\s+)[\d.]+/, "\\1#{next_branch_number}.0")
    content.sub!(/(Release:\s+).+$/, "\\11\%{dist}")
    content.sub!(/(Source1:\s+manageiq-)\d+\w+(\.repo)/, "\\1#{rpm_repo_name}\\2")
    unless content.include?(changelog_text)
      content.sub!("\%changelog", "\%changelog\n#{changelog_version}-1\%{dist}\n#{changelog_text}\n")
    end
    spec.write(content)

    # Modify rpm_spec changelog
    changelog = root.join("rpm_spec", "changelog")
    content = changelog.read
    unless content.include?(changelog_text)
      content.sub!("\%changelog", "\%changelog\n#{changelog_version}.0-1\n#{changelog_text}\n")
    end
    changelog.write(content)

    # Commit
    files_to_update = [dockerfile, options, old_package, new_package, spec, changelog]
    exit $?.exitstatus unless system("git add #{files_to_update.join(" ")}")
    exit $?.exitstatus unless system("git commit -m 'Changes after new branch #{branch}'")

    puts
    puts "The commit on #{current_branch} has been created."
    puts "Run the following to push to the upstream remote:"
    puts
    puts "\tgit push upstream #{current_branch}"
    puts
  end
end
