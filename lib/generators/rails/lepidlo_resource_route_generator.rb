require 'rails/generators.rb'
require 'rails/generators/rails/resource_route/resource_route_generator.rb'

module Rails
  module Generators
    class LepidloResourceRouteGenerator < ::Rails::Generators::ResourceRouteGenerator

      def add_resource_route
        return if options[:actions].present?

        # iterates over all namespaces and opens up blocks
        regular_class_path.each_with_index do |namespace, index|
          write("namespace :#{namespace} do", index + 1)
        end

        # inserts the primary resource
        write("resources :#{file_name.pluralize}, concerns: :resourcable", route_length + 1)

        # ends blocks
        regular_class_path.each_index do |index|
          write("end", route_length - index)
        end

        # route prepends two spaces onto the front of the string that is passed, this corrects that
        route route_string[2..-1]
      end



    end
  end
end
