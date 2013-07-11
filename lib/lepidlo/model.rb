# This is the module which makes any class behave like ActiveModel.
module Lepidlo
  module Model
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Model
      include ActiveModel::Serialization
      include ActiveModel::ForbiddenAttributesProtection
      include ActiveModel::AttributeMethods
      include ActiveModel::Dirty
    end

    # Always return true so when using form_for, the default method will be post.
    def new_record?
      true
    end

    # Always return nil so when using form_for, the default method will be post.
    def id
      nil
    end

    def destroyed?
      true
    end

  end
end
