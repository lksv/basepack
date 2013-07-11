module Lepidlo
  module Forms
    module Factories
      class Base
        FIELDS = {
          has_one_association: Fields::HasOneAssociation,
          has_many_association: Fields::HasManyAssociation,
          belongs_to_association: Fields::BelongsToAssociation,
          has_and_belongs_to_many_association: Fields::HasAndBelongsToManyAssociation,
        }

        def initialize(form_class = Forms::Base, group_class = Groups::Base)
          @form_class   = form_class
          @group_class  = group_class
        end

        def build_form(form)
          form
        end

        def new_form(*args)
          @form_class.new(self, *args).build_from_factory
        end

        def new_group(form, attributes)
          @group_class.new(form, attributes)
        end

        def new_field(name, form, attributes)
          if klass = FIELDS[field_attr(attributes, :type)]
            klass.new(name, form, attributes)
          else
            Fields::Base.new(name, form, attributes)
          end
        end

        private

        def field_attr(attributes, name)
          if attributes
            if attributes.respond_to? name
              attributes.send(name)
            else
              attributes[name]
            end
          end
        end

      end
    end
  end
end

