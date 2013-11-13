# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'casted_hash/version'

Gem::Specification.new do |spec|
  spec.name          = "casted_hash"
  spec.version       = CastedHash::VERSION
  spec.authors       = ["Stephan Kaag"]
  spec.email         = ["stephan@ka.ag"]
  spec.description = spec.summary = "A casted hash"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.add_dependency "equalizer", ">= 0.0.7"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5"
  spec.add_development_dependency "coveralls"
end