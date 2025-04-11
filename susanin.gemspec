# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'susanin/version'

Gem::Specification.new do |spec|
  spec.name          = "susanin"
  spec.version       = Susanin::VERSION
  spec.authors       = ["Alexey Osipenko"]
  spec.email         = ["alexey@cimon.io"]
  spec.summary       = %q{polymorphic_url extention to help with route generation}
  spec.description   = %q{This gem simplify the route generation which generates via `polymorphic_url` method}
  spec.homepage      = "https://github.com/cimon-io/susanin"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 5.0.0", "< 9.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "simplecov"
end
