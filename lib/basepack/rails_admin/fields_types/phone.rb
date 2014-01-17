require 'rails_admin/config/fields/types/string'
require 'phony'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Phone < RailsAdmin::Config::Fields::Types::String
          # Register field type for the type loader
          RailsAdmin::Config::Fields::Types::register(self)

          register_instance_option :pretty_value do
            if value.nil?
              nil
            else
              options = {}
              options[:format] = format if format.present?
              options[:spaces] = spaces if spaces.present?
              if Phony.plausible?(normalized_value)
                Phony.formatted(normalized_value, options).html_safe
              else
                value.html_safe
              end
            end
          end 

          register_instance_option :cc do
            nil
          end
          register_instance_option :ndc do
            nil
          end
          register_instance_option :format do
            nil
          end
          register_instance_option :spaces do
            nil
          end

          register_instance_option :export_value do
            value.inspect
          end

          # in case you want to save normalized value
          # must be called from controller
          # def parse_input(params)
          #   raise params[name].inspect
          #   params[name] = Phony.normalize(params[name], {cc: cc, ndc: ndc}) if params[name].present?
          # end

          def normalized_value
            options = {}
            options[:cc] = cc if cc.present? 
            options[:ndc] = ndc if ndc.present?
            Phony.normalize(value, options)
          end
        end 
      end 
    end 
  end 
end