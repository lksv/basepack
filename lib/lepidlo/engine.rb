require 'csv'
require 'rails_admin'
require 'inherited_resources'
require 'select2-rails'
require 'bootstrap-modal-rails'
require 'underscore-rails'
require 'underscore-string-rails'
require 'rails-i18n'
require 'cancan'
require 'ransack'
require 'simple_form'
require 'rspec-rails'
require 'factory_girl_rails'

module Lepidlo
  class Engine < ::Rails::Engine
    config.autoload_paths += [root.join('lib')]
    #if Rails.env.development?
    #  config.to_prepare do
    #    Rails.logger.debug "RELOADING LEPIDLO"
    #    require_dependency Lepidlo::Engine.root.join('lib', 'lepidlo').to_s
    #  end
    #end
    
    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end

end
