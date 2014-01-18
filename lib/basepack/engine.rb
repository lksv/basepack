require 'csv'
require 'rails_admin'
require 'inherited_resources'
require 'select2-rails'
require 'bootstrap-sass' #needs to be required before bootstrap-modal-rails
require 'bootstrap-modal-rails'
require 'underscore-rails'
require 'underscore-string-rails'
require 'rails-i18n'

module Basepack
  class Engine < ::Rails::Engine
    config.autoload_paths += [root.join('lib')]
    #if Rails.env.development?
    #  config.to_prepare do
    #    Rails.logger.debug "RELOADING BASEPACK"
    #    require_dependency Basepack::Engine.root.join('lib', 'basepack').to_s
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
