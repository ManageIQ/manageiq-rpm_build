#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)
require 'manageiq/rpm_build/extra_package'

Dir.chdir(ManageIQ::RPMBuild::ExtraPackage::PACKAGES_DIR) do
  directories = (Dir["*"] - ["."]).reject { |o| !File.directory?(o) }
  packages    = ARGV & directories
  extras      = ARGV - directories
  packages    = directories if packages.empty?

  if !extras.empty?
    puts "EXTRAS: #{extras.join(" ")}"
    puts "Exiting!!!"
    exit 1
  end

  puts "PACKAGES TO BUILD: #{packages.join(" ")}"

  packages.each do |package|
    puts "========== Package: #{package} =========="
    ManageIQ::RPMBuild::ExtraPackage.new(package).run_build
  end
end
