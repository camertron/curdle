$:.unshift File.expand_path('lib', __dir__)
require 'curdle/version'

Gem::Specification.new do |s|
  s.name     = 'curdle'
  s.version  = ::Curdle::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron/curdle'

  s.description = s.summary = 'Programmatically remove Sorbet type annotations from Ruby code.'

  s.platform = Gem::Platform::RUBY

  s.add_dependency 'parser', '~> 3.1'

  s.add_development_dependency 'rspec'

  s.require_path = 'lib'
  s.executables << 'curdle'

  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'LICENSE', 'CHANGELOG.md', 'README.md', 'Rakefile', 'curdle.gemspec']
end
