module Basepack
  module Import
    module Importable
      extend ActiveSupport::Concern

      included do
        association_name = Basepack::Settings.import.association_name
        association_name_join_table = Basepack::Settings.import.association_name_join_table
        if association_name
          has_many association_name_join_table,
                   as: :importable, inverse_of: :importable, dependent: :destroy, class_name: 'Basepack::ImportImportable'
          has_many association_name, through: association_name_join_table
        end
      end

      module ClassMethods
        def find_or_initialize_for_import(attrs)
          Basepack::Import::Importable.find_or_initialize_for_import(self, attrs)
        end
        alias :find_or_initialize_for_import! :find_or_initialize_for_import
      end

      def around_import(import, &block)
        yield
      end
      alias :around_import! :around_import

      def self.find_or_initialize_for_import(model, attrs, key = nil)
        key ||= model.primary_key
        if attrs[key]
          object = model.where(key => attrs[key]).first_or_initialize
          object.assign_attributes(attrs.except(key))
          object
        else
          model.new(attrs)
        end
      end
    end
  end
end
