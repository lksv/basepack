module Lepidlo
  module Forms
    module Fields
      class HasOneAssociation < Fields::SingleAssociation
        attr_default :editable, [:nested_form] do
          (nested_form || form.resource.respond_to?("#{name}_id=")) && super
        end

        attr_default :method_name, [:nested_form] do
          nested_form ? "#{name}_attributes".to_sym  : "#{name}_id".to_sym
        end

        def selected_id
          value.try :id
        end
      end
    end
  end
end
