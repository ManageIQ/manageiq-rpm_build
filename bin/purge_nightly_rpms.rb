#!/usr/bin/env ruby

$LOAD_PATH << File.expand_path("../lib", __dir__)

require 'manageiq-rpm_build'

ManageIQ::RPMBuild::NightlyBuildPurger.new.run
