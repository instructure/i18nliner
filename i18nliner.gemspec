# -*- encoding: utf-8 -*-
 
Gem::Specification.new do |s|
  s.name = 'i18nliner'
  s.version = '0.1.0'
  s.summary = 'I18n made simple'
  s.description = 'No .yml files. Inline defaults. Optional keys. Inferred interpolation values. Wrappers and blocks, so your templates look template-y and your translations stay HTML-free.'

  s.required_ruby_version     = '>= 1.9.3'
  s.required_rubygems_version = '>= 1.3.5'

  s.author            = 'Jon Jensen'
  s.email             = 'jenseng@gmail.com'
  s.homepage          = 'http://github.com/jenseng/i18nliner'

  s.files = %w(LICENSE.txt Rakefile README.md) + Dir['{lib,spec}/**/*.{rb,rake}']
  s.add_dependency('activesupport', '>= 3.0')
  s.add_dependency('ruby_parser', '~> 3.10')
  s.add_dependency('sexp_processor', '~> 4.10')
  s.add_dependency('ruby2ruby', '~> 2.4')
  s.add_dependency('globby', '>= 0.1.1')
  s.add_dependency('erubi', '~> 1.7.1')
  s.add_dependency('ya2yaml', '0.31')
  s.add_dependency('nokogiri', '>= 1.5.0')
  s.add_development_dependency('rspec', '~> 3.6.0')
  s.add_development_dependency('rspec-mocks', '~> 3.6.0')
end
