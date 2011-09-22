lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'mongoid/mapreduce/version'

Gem::Specification.new do |s|
  s.name = "mongoid-mapreduce"
  s.version = Mongoid::MapReduce::VERSION
  s.authors = ['Jason Coene']
  s.email = ['jcoene@gmail.com']
  s.homepage = 'http://github.com/jcoene/mongoid-mapreduce'
  s.summary = 'Simple map-reduce functionality for your Mongoid models'
  s.description = 'Mongoid MapReduce provides simple aggregation features for your Mongoid models'

  s.add_dependency 'mongoid', '~> 2.0'
  s.add_dependency 'bson_ext', '~> 1.3'
  s.add_development_dependency 'growl'
  s.add_development_dependency 'rake', '~> 0.9.2'
  s.add_development_dependency 'rspec', '~> 2.6'
  s.add_development_dependency 'guard-rspec', '~> 0.4.3'

  s.files = Dir["lib/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.md"]
  s.require_paths = ['lib']
end
