# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gitrob/version'

Gem::Specification.new do |spec|
  spec.name          = "gitrob"
  spec.version       = Gitrob::VERSION
  spec.authors       = ["Michael Henriksen"]
  spec.email         = ["michenriksen@neomailbox.ch"]
  spec.summary       = %q{Reconnaissance tool for GitHub organizations.}
  spec.description   = %q{Reconnaissance tool for GitHub organizations.}
  spec.homepage      = "https://github.com/michenriksen/gitrob"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "httparty", "~> 0.13"
  spec.add_dependency "methadone", "~> 1.7"
  spec.add_dependency "highline", "~> 1.6"
  spec.add_dependency "paint", "~> 0.8"
  spec.add_dependency "ruby-progressbar", "~> 1.6"
  spec.add_dependency "thread", "~> 0.1"
  spec.add_dependency "sinatra", "~> 1.4"
  spec.add_dependency "thin", "~> 1.6"
  spec.add_dependency "datamapper", "~> 1.2"
  spec.add_dependency "dm-postgres-adapter"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "webmock", "~> 1.20"
end
