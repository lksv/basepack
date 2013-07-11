module Lepidlo
  module Forms
    module Fields
      class HasManyAssociation < Fields::Base
        attr_default :partial, [:nested_form] do
          File.join('forms', 'edit', nested_form ? 'form_nested_many' : 'form_filtering_multiselect')
        end

        attr_default :orderable do
          false
        end

        attr_default :inline_add do
          true
        end

        attr_default :method_name, [:nested_form] do
          nested_form ? "#{name}_attributes".to_sym : "#{name.singularize}_ids".to_sym  # name_ids
        end

        def build_resource
          # TODO - raise exception for `through' assoc: form.resource_class.reflect_on_association(name).nested?
          value.build
        end
      end
    end
  end
end
