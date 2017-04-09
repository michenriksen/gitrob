# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gitrob/version"

Gem::Specification.new do |spec|
  spec.name          = "gitrob"
  spec.version       = Gitrob::VERSION
  spec.authors       = ["Michael Henriksen"]
  spec.email         = ["michenriksen@neomailbox.ch"]

  spec.summary       = %q{Reconnaissance tool for GitHub organizations}
  spec.homepage      = "https://github.com/michenriksen/gitrob"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "colorize", "~> 0.7"
  spec.add_dependency "highline", "~> 1.7"
  spec.add_dependency "thread", "~> 0.2"
  spec.add_dependency "ruby-progressbar", "~> 1.7"
  spec.add_dependency "sinatra", "~> 1.4"
  spec.add_dependency "thin", "~> 1.6"
  spec.add_dependency "pg", "~> 0.18"
  spec.add_dependency "sequel", "~> 4.27"
  spec.add_dependency "github_api", "0.13"
  spec.add_dependency "hashie", "~> 3.5", ">= 3.5.5"
  spec.add_dependency "sucker_punch", "~> 2.0", ">= 2.0.1"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "webmock"
end
