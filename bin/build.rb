#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/rpm_build'
require 'optimist'

opts = Optimist.options do
  opt :build_type, "nightly or release", :type => :string, :default => "nightly"
  opt :git_ref,    "Git ref to use (default: git_ref specified in options.yml)", :type => :string
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
gemset.restore_environment_variables

# Create tarballs
tar_build = ManageIQ::RPMBuild::GenerateTarFiles.new
tar_build.create_core_tarball
tar_build.create_gemset_tarball
tar_build.create_appliance_tarball

puts "\n\nTARBALL BUILT SUCCESSFULLY"

# Build RPMs
if ENV['COPR_RPM_BUILD']
  release_name = build_type == "release" ? git_ref : ""
  ManageIQ::RPMBuild::BuildCopr.new("manageiq", release_name).generate_rpm
end

puts "\n\nRPM BUILT SUCCESSFULLY"
