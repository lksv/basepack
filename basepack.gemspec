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
  spec.add_dependency 'rails', '~> 4'
  spec.add_dependency 'rails_admin', '>= 0.6.2'
  spec.add_dependency 'underscore-rails'
  spec.add_dependency 'underscore-string-rails'
  spec.add_dependency 'ejs'
  spec.add_dependency 'bootstrap-modal-rails'
  #spec.add_dependency 'inherited_resources' #FIXME: forked version included to Gemfile, waiting for #366 to be releaed
  spec.add_dependency 'haml-rails'
  spec.add_dependency "parslet"
  spec.add_dependency "cancan", "~> 1.6"
  spec.add_dependency 'settingslogic'
  spec.add_dependency 'bootstrap-wysihtml5-rails' #for wysihtml5 field

  spec.add_dependency 'rails-i18n'
  spec.add_dependency "select2-rails"
  spec.add_dependency "polyamorous" #, :github => "activerecord-hackery/polyamorous"
  spec.add_dependency 'ransack', '~> 1.2.3'
  spec.add_dependency 'kaminari'
  spec.add_dependency "simple_form"
  spec.add_dependency "nested_form"
  spec.add_dependency "phony", '~> 2.1.4'

  # assets
  spec.add_dependency 'sass-rails', '~> 4.0'
  spec.add_dependency 'bootstrap-sass', '~> 2.2'
  spec.add_dependency 'bootbox-rails', '~>0.1' #v0.2 is for Bootstrap 3
  spec.add_dependency 'font-awesome-rails', ['~> 3.0']
  spec.add_dependency 'coffee-rails', '~> 4.0'
  spec.add_dependency 'jquery-cookie-rails'
  spec.add_dependency 'fancytree-rails', "~> 0.0.2"

  spec.add_dependency 'psych', '~> 2.0.5'
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency "sqlite3"
  spec.files = Dir['Gemfile', 'README.md', 'Rakefile', "{app,config,db,lib}/**/*"]
  spec.licenses = ['LGPL']
  spec.homepage = 'https://github.com/lksv/basepack'
  spec.require_paths = ['lib']
  spec.required_rubygems_version = '>= 1.3.5'
  #spec.signing_key = File.expand_path("~/.gem/private_key.pem") if $0 =~ /gem\z/
  spec.test_files = Dir["spec/**/*"]

end
