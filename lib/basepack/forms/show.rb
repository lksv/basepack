module Basepack
  module Forms
    class Show < Forms::Base
      def default_partial
        'forms/show'
      end

      def render_field!(field)
        if field.partial_show.present?
          view.render field.partial_show, form: self, field: field
        else
          view.form_field_show(field)
        end
      end
    end
  end
end

