module Basepack
  module Forms
    class Export < Forms::Base
      attr_reader :query_form

      def initialize(factory, chain, options = {})
        super(factory, chain, options)
        @query_form = options[:query_form]
      end

      def view=(view)
        super
        @query_form.view = view if @query_form
      end

      def path
        view.polymorphic_path([:export, association_chain, resource_class].flatten)
      end

      def default_partial
        'forms/export'
      end

      def collection
        @query_form ? @query_form.collection : []
      end

      def schema_from_params(params = nil)
        schema_from_fields(fields_from_params(params))
      end

      def schema_from_fields(fields)
        schema = { only: [], methods: [], include: {} }

        fields.each do |nfields|
          if nfields.is_a? Array
            # nested form
            f = nfields.first.form.nested_in
            schema[:include][f.name] = schema_from_fields(nfields)
          else
            f = nfields
            if f.polymorphic?
              schema[:methods] << f.method_name << f.association.foreign_type
            elsif f.virtual?
              schema[:methods] << f.method_name
            else
              schema[:only] << f.name
            end
          end
        end

        schema
      end

      def fields_from_params(params = nil)
        if params.present?
          fields = []
          Array.wrap(params).each do |name|
            if name.is_a? Hash
              name.each {|n, v| fields << fields_for_field(visible_field(n.to_sym), v) }
            else
              fields << fields_for_field(visible_field(name.to_sym))
            end
          end
          fields
        else
          visible_fields.map {|f| fields_for_field(f)}
        end
      end

      def csv_header(fields)
        fields.flatten.map {|field| field.nested_label}
      end

      def csv_row_for_resource(resource, fields)
        with_resource(resource) do
          row = []
          fields.each do |nfields|
            if nfields.is_a? Array
              # nested form
              nform = nfields.first.form
              f = nform.nested_in
              values = f.multiple? ? f.value : [f.value]
              values = values.map {|v| nform.csv_row_for_resource(v, nfields)}
              nfields.zip(*values) {|nf, *v| row << v.join(',') }
            else
              f = nfields
              if f.polymorphic?
                row << resource.try(f.method_name) << resource.try(f.association[:foreign_type])
              else
                row << f.export_value
              end
            end
          end
          row
        end
      end

      private

      def fields_for_field(field, params = nil)
        if field and !field.form.nested_in and !field.inverse_of_nested_in? and nform = field.nform
            nform.fields_from_params(params)
        else
          field
        end
      end
    end
  end
end

