#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/rpm_build'

# Clone source repos
ManageIQ::RPMBuild::SourceRepos.new.populate

# Generate gemset
gemset = ManageIQ::RPMBuild::GemSet.new
gemset.backup_environment_variables
gemset.set_environment_variables
gemset.recreate_gem_home
gemset.populate_gem_home

# Create 'manageiq' tarballs
tar_build = ManageIQ::RPMBuild::MakeTarFile.new
tar_build.create_manageiq_tarball

# Scrub the gemset only after it is used to generate the tarfile.
gemset.scrub
gemset.restore_environment_variables

# Create 'manageiq-appliance' and 'manageiq-gemset' tarballs
tar_build.create_gemset_tarball
tar_build.create_appliance_tarball

puts "\n\nTARBALL BUILT SUCCESSFULLY"

# Build RPMs
if ENV['COPR_RPM_BUILD']
  ManageIQ::RPMBuild::RpmBuild.new("manageiq").generate_rpm
  ManageIQ::RPMBuild::RpmBuild.new("manageiq-gemset").generate_rpm
  ManageIQ::RPMBuild::RpmBuild.new("manageiq-appliance").generate_rpm
end

puts "\n\nRPM BUILT SUCCESSFULLY"
