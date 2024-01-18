#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/rpm_build'
require 'optimist'

opts = Optimist.options do
  opt :build_type,      "nightly or release", :type => :string, :default => "nightly"
  opt :git_ref,         "Git ref to use (default: git_ref specified in options.yml)", :type => :string, :default => ManageIQ::RPMBuild::OPTIONS.repos.ref
  opt :update_rpm_repo, "Publish the resulting RPMs to the public repository?"
end
Optimist.die "build type must be either nightly or release" unless %w[nightly release].include?(opts[:build_type])

build_type = opts[:build_type]
git_ref    = opts[:git_ref]

# Setup source repos and build environment
puts "XXX #{Time.now.utc} SetupSourceRepos "
ManageIQ::RPMBuild::SetupSourceRepos.new(git_ref).populate
puts "XXX #{Time.now.utc} SetupSourceRepos  DONE"

# Generate 'ansible-venv' contents
puts "XXX #{Time.now.utc} GenerateAnsibleVenv "
ManageIQ::RPMBuild::GenerateAnsibleVenv.new.populate
puts "XXX #{Time.now.utc} GenerateAnsibleVenv  DONE"

# Generate 'gemset' contents
puts "XXX #{Time.now.utc} GenerateGemSet "
gemset = ManageIQ::RPMBuild::GenerateGemSet.new
gemset.backup_environment_variables
gemset.set_environment_variables
gemset.recreate_gem_home
gemset.populate_gem_home(build_type)
puts "XXX #{Time.now.utc} GenerateGemSet  DONE"

# Generate 'core' contents
puts "XXX #{Time.now.utc} GenerateCore "
ManageIQ::RPMBuild::GenerateCore.new.populate
puts "XXX #{Time.now.utc} GenerateCore  DONE"

# Scrub the gemset only after it is used to generate 'core' contents
puts "XXX #{Time.now.utc} gemset scrub "
gemset.scrub
puts "XXX #{Time.now.utc} gemset scrub  DONE"

# Create tarballs
puts "XXX #{Time.now.utc} GenerateTarFiles create_tarballs "
ManageIQ::RPMBuild::GenerateTarFiles.new.create_tarballs
puts "XXX #{Time.now.utc} GenerateTarFiles create_tarballs  DONE"

# Generate manifest with license info for gems and npm packages
puts "XXX #{Time.now.utc} generate_dependency_manifest "
gemset.generate_dependency_manifest
puts "XXX #{Time.now.utc} generate_dependency_manifest  DONE"

puts "XXX #{Time.now.utc} restore_environment_variables "
gemset.restore_environment_variables
puts "XXX #{Time.now.utc} restore_environment_variables  DONE"

# Create manifest tarball
puts "XXX #{Time.now.utc} GenerateTarFiles create_manifest_tarball "
ManageIQ::RPMBuild::GenerateTarFiles.new.create_manifest_tarball
puts "XXX #{Time.now.utc} GenerateTarFiles create_manifest_tarball  DONE"

puts "\n\nTARBALL BUILT SUCCESSFULLY"

# Build RPMs
release_name = build_type == "release" ? git_ref : ""
puts "XXX #{Time.now.utc} BuildCopr generate_rpm "
ManageIQ::RPMBuild::BuildCopr.new(release_name).generate_rpm
puts "XXX #{Time.now.utc} BuildCopr generate_rpm  DONE"

if opts[:update_rpm_repo]
  ManageIQ::RPMBuild::BuildUploader.new(:release => build_type == "release").upload
  ManageIQ::RPMBuild::NightlyBuildPurger.new.run
  ManageIQ::RPMBuild::RpmRepo.new.update
end

puts "\n\nRPM BUILT SUCCESSFULLY"
