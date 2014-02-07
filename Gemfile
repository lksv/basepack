source "https://rubygems.org"
ruby '2.0.0'

# Declare your gem's dependencies in basepack.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

group :development do
  gem 'annotate'
  gem 'better_errors'
  # chrome extension rails_panel
  gem 'rails_panel'
  gem 'binding_of_caller'
  gem 'meta_request'
end

group :test, :development do
  # types
  gem 'bootstrap-wysihtml5-rails'
  gem "acts-as-taggable-on"

  gem 'cancan'
  gem 'devise'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'capybara'
  gem 'warden'
  gem 'database_cleaner'
  gem 'dragonfly', '~> 1.0.2'
  gem 'rack-cache', :require => 'rack/cache'
  gem 'timecop'
  gem 'settingslogic'
  gem 'ransack'
  gem 'delayed_job_active_record', "~> 4.0"

  gem 'poltergeist'
  gem 'jquery-rails'
  gem "jquery-turbolinks"
  gem "turbolinks"
  gem "bootbox-rails"
  gem 'sass-rails', '~> 4.0.0'
  gem 'bootstrap-sass', '~> 2.2'
  gem 'launchy'
  gem "twitter-bootstrap-rails", "~> 2.2.8"
  gem "selenium-webdriver"
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'
