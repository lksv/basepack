require 'rails_admin/i18n_support'

module Lepidlo
  module Forms
    class Edit < Forms::Base
      class << self
        include RailsAdmin::I18nSupport

        def data_picker_options
          {
            dateFormat:        date_format, # TODO - without %d -> dd, ...
            dayNames:          day_names,
            dayNamesShort:     abbr_day_names,
            dayNamesMin:       abbr_day_names,
            firstDay:          "1",
            monthNames:        month_names,
            monthNamesShort:   abbr_month_names,
          }
        end
      end

      delegate :input, :association, :object, :input_field, :check_box,
               :link_to_add, :link_to_remove, :hidden_field, :object_name, to: :simple_form

      attr_reader :simple_form
      attr_accessor :builder_default_options
      attr_accessor :path

      def initialize(factory, chain, options = {})
        super
        @path = options[:path]
        @builder_default_options = {
          html:     { multipart: true, class: 'form-horizontal denser' },
          defaults: { input_html: { class: 'span6'} }
        }
      end

      def path
        @path ||= view.url_for(chain)
      end

      def default_partial
        'forms/edit'
      end

      def builder
        simple_form
      end

      def with_simple_form(simple_form, &block)
        @simple_form = simple_form
        begin
          yield(self)
        ensure
          @simple_form = nil
        end
      end

      render :form do |options = nil, &block|
        options = (options || {}).dup.reverse_merge!(@builder_default_options)
        options[:url] ||= path

        view.simple_nested_form_for(chain, options) do |simple_form|
          with_simple_form(simple_form) do
            view.safe_concat render_setup_form
            view.safe_concat(view.capture(self, &block)) if block
          end
        end
      end

      render :setup_form do
        view.form_setup_simple_form(simple_form)
      end

      render :nested_form do |field, options = nil, &block|
        options = (options || {}).reverse_merge( defaults: @builder_default_options[:defaults] )

        resource.send("build_#{field.name}") unless field.multiple? or field.value

        simple_form.fields_for(field.name, options) do |nested_form|
          # this block is called out of order of superiors nested_forms in case of field.multiple?
          nested_form.object ||= field.value.build if field.multiple? # TODO is this necessary? can be #new_form moved outside of this block?
          new_form(nested_form.object, nested_in: field).with_simple_form(nested_form) {|form| view.capture(form, &block) }
        end
      end

      render :fields do
        view.render "forms/form_fields", form: self
      end

      render :filteringselect do |field, value = nil|
        value ||= Array.wrap(field.value)
        p_key = field.associated_primary_key || :id

        options = (field.html_attributes || {}).dup
        options[:value] = value.map {|v| v.send(p_key) }.join(',')
        options[:data] ||= {}
        options[:data].reverse_merge!(
          filteringselect: true,
          options: {
            multiple:       field.multiple,
            placeholder:    I18n.t('admin.misc.search'),
            required:       field.required?,
            remote_source:  field.options_source,
            remote_source_params: field.options_source_params || {},
            init:           Hash[value.map {|v| [v.send(p_key), view.html_escape(v.to_label)] }],
          }
        )
        options.reverse_merge!(@builder_default_options[:defaults][:input_html]) if @builder_default_options[:defaults]
        simple_form.hidden_field field.method_name, options
      end

      def textfield_options(field)
        options = (field.html_attributes || {}).dup
        options.reverse_merge!(@builder_default_options[:defaults][:input_html]) if @builder_default_options[:defaults]
        options
      end

      render :textfield do |field, options = {}|
        simple_form.input_field field.method_name, textfield_options(field).reverse_merge(options)
      end

      render :actions do
        view.render "forms/buttons/submit"
      end

      def render_field!(field)
        if field.read_only?
          simple_form.input field.name, label: field.label, hint: field.help, required: field.required? do
            field.pretty_value
          end
        else
          view.render field.partial, form: self, field: field
        end
      end

    end
  end
end


