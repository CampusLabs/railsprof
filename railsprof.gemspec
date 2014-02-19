# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'railsprof/version'

Gem::Specification.new do |spec|
  spec.name          = 'railsprof'
  spec.version       = Railsprof::VERSION
  spec.authors       = ['Clifton King']
  spec.email         = ['cliftonk@gmail.com']
  spec.summary       = 'command line rbline prof for rails apps'
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = 'http://orgsync.github.io'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.test_files    = `git ls-files -- spec/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '> 1.3'
  # spec.add_development_dependency 'rspec', '~> 1.5'
  spec.add_runtime_dependency 'rake', '~> 10.1.1'
  spec.add_runtime_dependency 'rails', '> 3.0'
  spec.add_runtime_dependency 'activesupport', '> 3.0'
  spec.add_runtime_dependency 'rblineprof', '~> 0.3.6'
end
