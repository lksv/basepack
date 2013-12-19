module Basepack
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

        def parse_input(params)
          if params[method_name].is_a? String
            params[method_name] = params[method_name].split ','
          else
            @delegate.parse_input(params) if @delegate
          end
        end

        # returns true only for for N-N associations
        def bulk_editable?
          #N-N association are only with:
          # has_many through: <join_table>, where join_table has foreign_keys for both associations

          reflection = abstract_model.model.reflect_on_association(name)
          (
            (ActiveRecord::Reflection::ThroughReflection === reflection) and
            (reflection.through_reflection.macro == :has_many) and
            (reflection.source_reflection.macro == :belongs_to)
          )

        end
      end
    end
  end
end
