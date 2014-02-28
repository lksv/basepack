module RailsAdmin
  module Config
    module Sections
      class TreeList < RailsAdmin::Config::Sections::List
        register_instance_option :partial do
          'forms/tree_list'
        end

        register_instance_option :extensions do
          ["persist"]
        end

        register_instance_option :select_mode do
          3
        end

        register_instance_option :dnd do
          {}
        end

      end
    end
  end
end

RailsAdmin::Config::Sections.included(RailsAdmin::Config::Model)

