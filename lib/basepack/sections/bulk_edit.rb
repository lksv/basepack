require 'rails_admin/config/sections/base'

module RailsAdmin
  module Config
      # Configuration of the bulk edit view
    module Sections
      class BulkEdit < RailsAdmin::Config::Sections::Edit
      end
    end
  end
end

RailsAdmin::Config::Sections.included(RailsAdmin::Config::Model)


