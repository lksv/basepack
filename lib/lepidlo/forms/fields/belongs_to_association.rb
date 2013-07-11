module Lepidlo
  module Forms
    module Fields
      class BelongsToAssociation < Fields::SingleAssociation
        # TODO
        #register_instance_option :sortable do
        #  @sortable ||= abstract_model.adapter_supports_joins? && associated_model_config.abstract_model.properties.map{ |p| p[:name] }.include?(associated_model_config.object_label_method) ? associated_model_config.object_label_method
        #end
        #
        #register_instance_option :searchable do
        #  @searchable ||= associated_model_config.abstract_model.properties.map{ |p| p[:name] }.include?(associated_model_config.object_label_method) ? [associated_model_config.object_label_method, {self.abstract_model.model => self.me
        #end

        attr_default :method_name, [:nested_form, :foreign_key] do
          nested_form ? "#{name}_attributes".to_sym : foreign_key
        end

        def selected_id
          form.resource.send(foreign_key)
        end

      end
    end
  end
end
