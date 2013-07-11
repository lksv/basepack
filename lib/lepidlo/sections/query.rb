module RailsAdmin
  module Config
    module Sections
      # Configuration of the query view
      class Query < RailsAdmin::Config::Sections::Base
      end
    end
  end
end

RailsAdmin::Config::Sections.included(RailsAdmin::Config::Model)

