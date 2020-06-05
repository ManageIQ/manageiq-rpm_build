#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/rpm_build'
require 'optimist'

opts = Optimist.options do
  opt :build_type,      "nightly or release", :type => :string, :default => "nightly"
  opt :git_ref,         "Git ref to use (default: git_ref specified in options.yml)", :type => :string
  opt :update_rpm_repo, "Publish the resulting RPMs to the public repository?"
end
Optimist.die "build type must be either nightly or release" unless %w[nightly release].include?(opts[:build_type])

build_type = opts[:build_type]
git_ref    = opts[:git_ref]

# Clone source repos
ManageIQ::RPMBuild::SetupSourceRepos.new(git_ref).populate

# Generate gemset
gemset = ManageIQ::RPMBuild::GenerateGemSet.new
gemset.backup_environment_variables
gemset.set_environment_variables
gemset.recreate_gem_home
gemset.populate_gem_home

# Generate 'core' contents
ManageIQ::RPMBuild::GenerateCore.new.populate

# Scrub the gemset only after it is used to generate 'core' contents
gemset.scrub

# Create tarballs
ManageIQ::RPMBuild::GenerateTarFiles.new.create_tarballs

# Generate manifest with license info for gems and npm packages
gemset.generate_dependency_manifest
gemset.restore_environment_variables

# Create manifest tarball
ManageIQ::RPMBuild::GenerateTarFiles.new.create_manifest_tarball

puts "\n\nTARBALL BUILT SUCCESSFULLY"

# Build RPMs
release_name = build_type == "release" ? git_ref : ""
ManageIQ::RPMBuild::BuildCopr.new(release_name).generate_rpm

if opts[:update_rpm_repo]
  ManageIQ::RPMBuild::BuildUploader.new(:release => build_type == "release").upload
  ManageIQ::RPMBuild::RpmRepo.new.update
end

puts "\n\nRPM BUILT SUCCESSFULLY"
