# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/resque_monit/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-resque_monit"
  spec.version       = Capistrano::ResqueMonit::VERSION
  spec.authors       = ["Gino Clement", "Jeremy Wadsack"]
  spec.email         = ["ginoclement@gmail.com", "jeremy@keylimetoolbox.com"]
  spec.summary       = "Deploying Resque and Monit using Capistrano."
  spec.description   = "A set of Capistrano scripts for configuring resque workers to be monitored by monit"
  spec.homepage      = "https://github.com/keylimetoolbox/capinstrano-resque_monit"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano", "~> 3.0"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
end
