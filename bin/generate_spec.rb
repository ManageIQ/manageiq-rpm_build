#!/usr/bin/env ruby

require 'pathname'

spec_dir = Pathname.new("../rpm_spec").expand_path(__dir__)
manageiq_spec = spec_dir.join("manageiq.spec.in").read

Dir.glob("#{spec_dir.join("subpackages/*")}") do |spec|
  subpackage_spec = File.read(spec)
  manageiq_spec.sub!("%changelog", "#{subpackage_spec}\n\n%changelog")
end

spec_dir.join("manageiq.spec").write(manageiq_spec)
