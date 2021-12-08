Dir.glob(File.expand_path("lib/tasks/*", __dir__)).sort.each { |f| load f }

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
