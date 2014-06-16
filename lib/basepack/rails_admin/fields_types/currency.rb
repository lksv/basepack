require 'rails_admin/config/fields/base'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Currency < RailsAdmin::Config::Fields::Base
          include ActionView::Helpers::NumberHelper

          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types.register(self)
          register_instance_option :pretty_value do
            if value.nil?
              nil
            else
              number_to_currency(value.to_f)
            end
          end
        end
      end
    end
  end
end
