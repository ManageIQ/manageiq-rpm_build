#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq/rpm_build'
require 'optimist'

opts = Optimist.options do
  opt :release_name, "release name (e.g. jansa-1) if release build", :type => :string
end

spec_dir = Pathname.new("../rpm_spec").expand_path(__dir__)
Dir.chdir(spec_dir) do
  ManageIQ::RPMBuild::BuildCopr.new(opts[:release_name].to_s).generate_spec_from_template
end
