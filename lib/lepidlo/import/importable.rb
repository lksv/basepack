module Lepidlo
  module Import
    module Importable
      extend ActiveSupport::Concern

      included do
        association_name = Lepidlo::Settings.import.association_name
        association_name_join_table = Lepidlo::Settings.import.association_name_join_table
        if association_name
          has_many association_name_join_table,
                   as: :importable, inverse_of: :importable, dependent: :destroy, class_name: 'Lepidlo::ImportImportable'
          has_many association_name, through: association_name_join_table
        end
      end

      module ClassMethods
        def find_or_initialize_for_import(attrs)
          Lepidlo::Import::Importable.find_or_initialize_for_import(self, attrs)
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
