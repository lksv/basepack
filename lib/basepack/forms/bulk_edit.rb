module Basepack
  module Forms
    class BulkEdit < Forms::Edit
      attr_accessor :query_form

      def initialize(factory, chain, options = {})
        super(factory, chain, options)
        @query_form = options[:query_form]
      end

      def collection
        @query_form ? @query_form.collection_without_pagination : []
      end

      def path
        @path ||= view.polymorphic_path([:bulk_update, chain].flatten, query_form.params)
      end


      def build_from_factory
        factory.build_form(self)
      end

      def default_partial
        'forms/bulk_edit'
      end

      def render_field!(field)
        if field.bulk_editable? and !field.read_only? and field.view_helper != :hidden_field
          field.required = false
          if field.bulk_edit_partial.present? and view.lookup_context.template_exists?(field.bulk_edit_partial, '', true)
            #rendering input field with bulk_edit extensions
            view.render field.bulk_edit_partial, form: self, field: field
          else
            #rendering common input field
            view.render field.partial, form: self, field: field
          end
        end
      end


    end
  end
end
