#!/usr/bin/env ruby

require 'bundler'
ENV["BUNDLE_GEMFILE"] = "/tmp/lock_generator/Gemfile"

# Set up working directory
require 'fileutils'
FileUtils.mkdir_p("/tmp/lock_generator/bundler.d")
FileUtils.cp("/mnt/Gemfile", "/tmp/lock_generator/")
FileUtils.cp("/mnt/Gemfile.release.rb", "/tmp/lock_generator/bundler.d/") if File.file?("/mnt/Gemfile.release.rb")
branch = Bundler.load.dependencies.detect { |i| i.name == "manageiq-api" }.branch
puts "Bundling for branch: #{branch}..."
exit $?.exitstatus unless system("git clone https://github.com/ManageIQ/manageiq-appliance.git -b #{branch} /tmp/manageiq-appliance")
FileUtils.cp("/tmp/manageiq-appliance/manageiq-appliance-dependencies.rb", "/tmp/lock_generator/bundler.d/")

# Generate Gemfile.lock
exit $?.exitstatus unless system({"APPLIANCE" => "true", "BUNDLE_GEMFILE" => ENV["BUNDLE_GEMFILE"]}, "bundle update --jobs=8")

# Generate the lockfiles
p = Bundler::LockfileParser.new(Bundler.read_file("#{ENV["BUNDLE_GEMFILE"]}.lock"))
lock_contents = p.specs.each_with_object("") do |gem, lock|
  next if gem.source.kind_of?(Bundler::Source::Git)
  lock << "ensure_gem \"#{gem.name}\", \"=#{gem.version}\"\n"
end

# Copy results back to the mounted manageiq repo
File.write("/mnt/bundler.d/Gemfile.release.rb", lock_contents)
FileUtils.cp("#{ENV["BUNDLE_GEMFILE"]}.lock", "/mnt/Gemfile.lock.release")

puts "Complete!"
