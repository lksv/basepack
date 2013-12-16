module Basepack
  class ImportImportable < ActiveRecord::Base
    self.table_name = :imports_importables

    klass = Basepack::Settings.import.model_name.safe_constantize
    belongs_to :import, inverse_of: :importables, class_name: "::#{klass}"

    if Basepack::Settings.import.association_name
      belongs_to :importable, polymorphic: true, inverse_of: Basepack::Settings.import.association_name_join_table
    else
      belongs_to :importable, polymorphic: true
    end

    validates_presence_of :import, :importable

    def to_label
      import.try(:to_label)
    end

    rails_admin do
      visible false
    end
  end
end
