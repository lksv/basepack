module RailsAdmin
  module Config
    module Sections
      # Configuration of the query view
      class Query < RailsAdmin::Config::Sections::Base
        register_instance_option :sort_by do
          nil
        end

        register_instance_option :sort_reverse? do
          false
        end
      end
    end
  end
end

RailsAdmin::Config::Sections.included(RailsAdmin::Config::Model)

