#!/usr/bin/env ruby

require 'bundler'
ENV["BUNDLE_GEMFILE"] = "/tmp/lock_generator/Gemfile"

# Set up working directory
require 'fileutils'
FileUtils.mkdir_p("/tmp/lock_generator/bundler.d")
FileUtils.cp("/mnt/Gemfile", "/tmp/lock_generator/")
FileUtils.cp("/mnt/Gemfile.release.rb", "/tmp/lock_generator/bundler.d/") if File.file?("/mnt/Gemfile.release.rb")

# Generate Gemfile.lock
exit $?.exitstatus unless system({"APPLIANCE" => "true", "BUNDLE_GEMFILE" => ENV["BUNDLE_GEMFILE"]}, "bundle update --jobs=8 --retry=3")

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
