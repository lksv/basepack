module Basepack
  module Forms
    module Fields
      class HasAndBelongsToManyAssociation < Fields::HasManyAssociation
        def bulk_editable?
          true
        end
      end
    end
  end
end

