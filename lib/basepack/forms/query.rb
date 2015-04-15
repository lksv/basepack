# This class construct form for filtering an resource
# For playing in console, you can instantiate by:
# Basepack::Forms::Factories::QueryRailsAdmin.new(helper).new_form(Subscription, {scope: Subscription.all, auth_object: Ability.new(User.first)})
module Basepack
  module Forms
    class Query < Forms::Base
      attr_reader   :query
      attr_reader   :edit_ql
      attr_reader   :params # parameters required to build similar form
      attr_accessor :ql
      attr_accessor :date_format
      attr_reader   :auth_object
      attr_reader   :filterql_options

      def initialize(factory, chain, options = {})
        super(factory, chain, options)

        @scope = options[:scope]
        @auth_object = options[:auth_object]
        @filterql_options = options[:filterql_options]
        @collection_includes = options[:collection_includes]

        if params = options[:params]
          @params = params.slice(:query, :ql, :f, :page, :per).reject {|k, v| v.empty?}
          @query = params[:query]

          if has_errors?
            @ql = params[:ql]
          elsif params[:edit_ql]
            @edit_ql = params[:edit_ql]
          end
        end
      end

      def collection
        @collection || begin
          query_from_params
          @collection
        end
      end

      def collection_without_pagination
        collection.offset(nil).limit(nil)
      end

      def resource_filter
        @resource_filter || begin
          query_from_params
          @resource_filter
        end
      end

      def has_errors?
        resource_filter.errors[:base].present?
      end

      def nested_filterable_field(name)
        filterable_field(name) || begin
          n = name.to_s.split('_')
          (n.size - 1).downto(1) do |count|
            if f = filterable_field(n[0, count].join('_').to_sym)
              return f.nform.nested_filterable_field(n[count..-1].join('_').to_sym)
            end
          end
          nil
        end
      end

      def field_nested_name(field)
        field.form.nested_in ? "#{field_nested_name(field.form.nested_in)}_#{field.name}" : field.name
      end

      def filterable_field(name)
        f = field(name)
        f.try(:filterable?) ? f : nil
      end

      def filterable_fields
        fields.select {|f| f.filterable? }
      end

      def present?
        @query or @ql or filtered_fields.present?
      end

      def setup
        {
          options: {
            regional: { datePicker: { dateFormat: date_format }.reverse_merge!(Basepack::Forms::Edit.data_picker_options) },
            predicates: FilterQL.predicates,
            enum_options: enum_options,
          },
          initial: initial_data,
        }
      end

      def filtered_fields
        @filtered_fields || begin
          if nested_in
            @filtered_fields = []
          else
            @filtered_fields = resource_filter.c.map do |condition|
              if condition.valid? and condition.attributes.size == 1
                if field = nested_filterable_field(condition.attributes.first.name.to_sym)
                  [field, condition.predicate_name, Query.localize_value(field, condition.predicate_name, condition.value)]
                end
              end
            end.concat(Array.wrap(resource_filter.custom_filters).map do |name, predicate_name, values|
              if field = nested_filterable_field(name.to_sym)
                [field, predicate_name, values]
              end
            end).compact
          end
        end
      end

      def filtered_fields_find(nested_field_name, condition = nil)
        filtered_fields.find do |f|
          (field_nested_name(f[0]) == nested_field_name) and 
          (condition ? (f[1] == condition) : true)
        end
      end

      def initial_data
        if @edit_ql
          init = []
        else
          init = filtered_fields.map do |field, predicate_name, values|
            {
              label:     field.nested_label,
              name:      field_nested_name(field),
              type:      field.type,
              value:     values,
              predicate: predicate_name,
              template:  field.render.to_s,
            }
          end
        end

        if @ql or @edit_ql
          init << {
            label:     I18n.t('basepack.query.query'),
            name:      'ql',
            type:      'ql',
            value:     @ql || conditions_to_ql,
            predicate: 'eq',
            template:  '',
          }
        end

        init
      end

      def conditions_to_ql
        FilterQL.conditions_to_ql(filtered_fields.map do |field, predicate_name, value|
          [field_nested_name(field), predicate_name, value]
        end)
      end

      def enum_options(fields = fields)
        res = {}
        Array.wrap(fields).each do |f|
          options = f.enum_options
          if options and f.filterable?
            #key f.name is not enought because of enum_options is called recursielly on assiciations
            res[field_nested_name(f)] = options
          elsif (f.association? and !nested_in and !f.polymorphic?)
            res.update(f.nform.enum_options)
          end
        end
        res
      end

      def date_format
        @date_format ||
          I18n.t("admin.misc.filter_date_format", :default => I18n.t("admin.misc.filter_date_format", :locale => :en))
      end

      def default_partial
        'forms/query'
      end

      def render_field!(field)
        # TODO view.render field.partial
      end

      def path
        view.polymorphic_path([:query, association_chain, resource_class].flatten)
      end

      def self.localize_value(field, predicate_name, value)
        return value if value.is_a? Array
        return "" if FilterQL.predicates[predicate_name][:type] == :boolean

        case field.type
        when :date, :datetime
          I18n.l(value.to_date)
        when :time
          I18n.l(value.to_time, :format => "%H:%M")
        else
          value
        end
      end

      private

      def query_from_params
        @resource_filter, @collection = Basepack::Utils.query_from_params(
          @scope,
          @params,
          {
            auth_object: @auth_object,
            filterql_options: @filterql_options,
          }
        )
        @collection = @collection.includes(@collection_includes) if @collection_includes
      end
    end
  end
end
