#!/usr/bin/env ruby

require_relative 'clone_repos'
require_relative 'generate_gemset'
require_relative 'rpm_build'

# Clone source repos
source_repos = SourceRepos.new
source_repos.populate

# Create tarballs
tarball_build = TarBuild.new
tarball_build.run

# Build RPMs
if ENV['COPR_RPM_BUILD']
  RpmBuild.new("manageiq").generate_rpm
  RpmBuild.new("manageiq-gemset").generate_rpm
  RpmBuild.new("manageiq-appliance").generate_rpm
end
