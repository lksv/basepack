require 'csv'
require 'rails_admin'
require 'inherited_resources'
require 'select2-rails'
require 'bootstrap-modal-rails'
require 'underscore-rails'
require 'underscore-string-rails'
require 'rails-i18n'

module Lepidlo
  class Engine < ::Rails::Engine
    config.autoload_paths += [root.join('lib')]
    #if Rails.env.development?
    #  config.to_prepare do
    #    Rails.logger.debug "RELOADING LEPIDLO"
    #    require_dependency Lepidlo::Engine.root.join('lib', 'lepidlo').to_s
    #  end
    #end
  end
end
