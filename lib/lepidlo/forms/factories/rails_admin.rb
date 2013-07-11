module Lepidlo
  module Forms
    module Factories
      class RailsAdmin < Factories::Base

        class Bindings
          def initialize(form, view)
            @form = form
            @view = view
          end

          def [](param)
            case param
            when :object
              @form.resource
            when :view
              @view
            when :controller
              @view.controller
            when :form
              @form
            end
          end
        end

        def initialize(section, view, form_class = Forms::Base, group_class = Groups::Base)
          super(form_class, group_class)
          @section      = section
          @view         = view
        end

        def build_form(form)
          bindings = Bindings.new(form, @view)

          Lepidlo::Utils.model_config(form.resource_class).send(@section).with(bindings).visible_groups.map do |g|
            i = 0
            fields = g.fields.sort_by {|f| [f.order, i += 1] } # stable sort

            form.group(g) do |group|
              fields.each do |f|
                group.field(f.name, f.with(bindings)) do |field|
                  def field.partial_delegated
                    partial = super.to_s
                    partial.include?('/') ? partial : File.join('forms', 'edit', partial)
                  end
                end
              end
            end
          end

          form
        end

      end
    end
  end
end
