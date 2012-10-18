# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/olelo/version'
require 'date'

Gem::Specification.new do |s|
  s.name              = 'olelo'
  s.version           = Olelo::VERSION
  s.date              = Date.today.to_s
  s.authors           = ['Daniel Mendler']
  s.email             = ['mail@daniel-mendler.de']
  s.summary           = 'Olelo is a git-based wiki.'
  s.description       = 'Olelo is a git-based wiki which supports many markup languages, tags, embedded TeX and much more. It can be extended through plugins.'
  s.homepage          = 'http://gitwiki.org/'
  s.rubyforge_project = s.name

  s.files         = `git ls-files | grep -P -v '^tools/'`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.add_runtime_dependency('tilt', ['~> 1.3.3'])
  s.add_runtime_dependency('slim', ['~> 1.3.3'])
  s.add_runtime_dependency('creole', ['~> 0.4.2'])
  s.add_runtime_dependency('nokogiri', ['~> 1.5.5'])
  s.add_runtime_dependency('mimemagic', ['~> 0.1.9'])
  s.add_runtime_dependency('rack', ['~> 1.4.1'])
  s.add_runtime_dependency('redcarpet', ['~> 2.1.1'])
  s.add_runtime_dependency('rugged', ['~> 0.17.0b6'])

  s.add_development_dependency('rake', ['>= 0.8.7'])
  s.add_development_dependency('sass', ['>= 3.1.0'])
end
