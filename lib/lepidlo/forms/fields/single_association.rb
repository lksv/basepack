module Lepidlo
  module Forms
    module Fields
      class SingleAssociation < Fields::Base
        attr_default :formatted_value do
          value.try? :to_label
        end

        attr_default :partial, [:nested_form] do
          File.join('forms', 'edit', nested_form ? 'form_nested_one' : 'form_filtering_select')
        end

        attr_default :inline_add do
          true
        end

        attr_default :inline_edit do
          true
        end

        attr_default :multiple do
          false
        end

        def build_resource
          value || form.resource.send("build_#{name}")
        end
      end

    end
  end
end
