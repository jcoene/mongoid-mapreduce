require 'bundler'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks

desc 'Run all specs in the spec directory'
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
