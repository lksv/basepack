require 'rails_admin/config/sections/base'

module RailsAdmin
  module Config
    module Sections
      # Configuration of the import view
      class Import < RailsAdmin::Config::Sections::Export
      end
    end
  end
end

RailsAdmin::Config::Sections.included(RailsAdmin::Config::Model)


