source "https://rubygems.org"
#ruby '2.1'

# Declare your gem's dependencies in basepack.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

#FIXME: forked version, waiting for #366 to be releaed. After that remove this line and use basepack.gemspec
gem 'inherited_resources', github: 'lksv/inherited_resources', branch: '#305_fetching_namespaced_model', ref: '93640c35200'
gem 'rails_admin', github: 'lksv/rails_admin', branch: 'cherrypick_2010', ref: '9595e19098c81c'

group :development do
  gem 'annotate'
  gem 'better_errors'
  # chrome extension rails_panel
  gem 'rails_panel'
  gem 'binding_of_caller'
  gem 'meta_request'
end

group :test, :development do
  gem "sqlite3"
  # types
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
  gem 'launchy'
  gem "twitter-bootstrap-rails", github: 'lksv/twitter-bootstrap-rails' #forked version - needs 95de3b0e (Fixed for Rails 4.1 and Ruby 2.1) to be releaed
  gem "selenium-webdriver"
  gem "simple_form"
  gem 'ancestry'
  gem 'jquery-cookie-rails'
  gem 'fancytree-rails', "~> 0.0.2"
  gem 'bootstrap-modal-rails'
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'
