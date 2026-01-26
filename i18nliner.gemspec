# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "i18nliner"
  s.version = "0.2.5"
  s.summary = "I18n made simple"
  s.description = <<~TEXT
    No .yml files. Inline defaults. Optional keys. Inferred interpolation values.
    Wrappers and blocks, so your templates look template-y and your translations stay HTML-free.
  TEXT

  s.required_ruby_version = ">= 3.2"

  s.author            = "Jon Jensen"
  s.email             = "jenseng@gmail.com"
  s.homepage          = "http://github.com/jenseng/i18nliner"
  s.metadata["rubygems_mfa_required"] = "true"

  s.files = %w[LICENSE.txt Rakefile README.md] + Dir["{lib,spec}/**/*.{rb,rake}"]

  s.add_dependency "activesupport", ">= 6.0"
  s.add_dependency "erubi", "~> 1.7"
  s.add_dependency "globby", ">= 0.1.1"
  s.add_dependency "i18n", ">= 1.8.6"
  s.add_dependency "nokogiri", ">= 1.5.0"
  s.add_dependency "prism", "~> 1.8"
  s.add_dependency "ruby2ruby", "~> 2.4"
  s.add_dependency "sexp_processor", "~> 4.10"
  s.add_dependency "ya2yaml", "0.31"
end
