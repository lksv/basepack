# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "basepack/version"

Gem::Specification.new do |spec|
  spec.name           = 'basepack'
  spec.authors        = ["Lukas Svoboda", "Max Anonymous"]
  spec.summary        = "Basepack for Rails"
  spec.description    = "Basepack for Rails"
  spec.email          = ['lukas.svoboda@gmail.com']
  spec.version        = Basepack::VERSION

  # if you add a dependency, please maintain alphabetical order
  spec.add_dependency 'rails', '~> 4.0.0'
  spec.add_dependency 'rails_admin', '>= 0.5.0'
  spec.add_dependency 'underscore-rails'
  spec.add_dependency 'underscore-string-rails'
  spec.add_dependency 'ejs'
  spec.add_dependency 'bootstrap-modal-rails'
  spec.add_dependency 'inherited_resources'
  spec.add_dependency 'haml-rails'
  spec.add_dependency "parslet"
  spec.add_dependency "cancan", ">= 1.6.9"
  spec.add_dependency 'settingslogic'

  spec.add_dependency 'rails-i18n'
  spec.add_dependency "select2-rails"
  spec.add_dependency 'ransack'
  spec.add_dependency 'kaminari'
  spec.add_dependency "simple_form"
  spec.add_dependency "nested_form"

  # assets
  spec.add_dependency 'sass-rails', '~> 4.0.0.rc1'
  spec.add_dependency 'bootstrap-sass', '~> 2.2'
  spec.add_dependency 'bootbox-rails'
  spec.add_dependency 'font-awesome-rails', ['~> 3.0']
  spec.add_dependency 'coffee-rails', '~> 4.0.0'

  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency "sqlite3"
  spec.files = Dir['Gemfile', 'README.md', 'Rakefile', "{app,config,db,lib}/**/*"]
  spec.licenses = ['LGPL']
  spec.homepage = 'https://github.com/basepack'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = '>= 1.3.5'
  #spec.signing_key = File.expand_path("~/.gem/private_key.pem") if $0 =~ /gem\z/
  spec.test_files = Dir["spec/**/*"]

end
