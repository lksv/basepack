module Basepack
  module Forms
    module Factories
      class QueryRailsAdmin < Factories::RailsAdmin
        def initialize(view, form_class = Forms::Query, group_class = Groups::Base)
          super(:query, view, form_class, group_class)
        end

        def build_form(form)
          super(form)

          rans_assoc = form.resource_class.ransackable_associations(form.auth_object)
          rans_attrs = form.resource_class.ransackable_attributes(form.auth_object)

          form.fields.each do |f|
            if f.association?
              f.filterable = rans_assoc.include?(f.name.to_s)
            elsif f.virtual?
              #  f.filterable = false
            else
              f.filterable = rans_attrs.include?(f.name.to_s) if f.filterable?
            end
          end

          form
        end
      end
    end
  end
end

