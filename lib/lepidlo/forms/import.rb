module Lepidlo
  module Forms
    class Import < Forms::Base
      attr_reader   :edit_form
      attr_reader   :show_form
      attr_reader   :list_form
      attr_reader   :builder
      attr_reader   :action_name
      attr_accessor :builder_default_options

      def initialize(factory, chain, options = {})
        super(factory, chain, options)

        @action_name = options[:action_name] || :import

        @builder_default_options = {
          as:       :import,
          html:     { multipart: true, class: 'form-horizontal denser' },
          defaults: { input_html: { class: 'span6'} }
        }

        if options[:show_form]
          @show_form = options[:show_form]
        end

        if options[:edit_form]
          @edit_form = options[:edit_form]
          @edit_form.builder_default_options[:as] = :import
          @edit_form.content_for_form do |form, opt = {}, &block|
            form.render_form!(opt) do
              view.safe_concat form.render_fields
              view.safe_concat(view.content_tag(:div, class: "pull-right") do
                form.view.render("forms/buttons/submit_create")
              end)
            end
          end
        end

        if options[:list_form]
          @list_form = options[:list_form]
          @list_form.content_for_row do |form, &block|
            view.content_tag(:tr, class: @show_form.resource.id == form.resource.id ? "success" : nil, &block)
          end
          @list_form.content_for_actions do |form|
            result = ''.html_safe
            result << form.render_action("Zobrazit", path(import_id: form.resource.id), "icon-eye-open",
                                         class: @show_form.resource.id == form.resource.id ? 'btn btn-mini disabled' : 'btn btn-mini',
                                        )
            result << form.render_action("Smazat", path(delete_id: form.resource.id), "icon-trash",
                                         class: 'btn btn-mini btn-danger',
                                         method: :delete,
                                         data: { confirm: "Jste si jistí?" })
            result
          end
        end
      end

      def path(params = {})
        view.polymorphic_path([@action_name, association_chain, resource_class].flatten, params)
      end

      def with_builder(builder, &block)
        @builder = builder
        begin
          yield(self)
        ensure
          @builder = nil
        end
      end

      def view=(view)
        super
        if @edit_form
          @edit_form.view = view
          @edit_form.path = path
        end
        @show_form.view = view if @show_form
        @list_form.view = view if @list_form
      end

      def default_partial
        'forms/import'
      end

      def field_nested_name(field)
        field.form.nested_in ? "#{field_nested_name(field.form.nested_in)}[#{field.method_name}]" : field.method_name
      end

      def fields_for_import_as_select_options
        @normal = [["Žádný", '']]
        @association = []

        visible_fields.each do |field|
          if !field.association?
            @normal << [field.label.to_s, field.method_name.to_s]
          elsif nform = field.nform
            # nested form
            next if field.multiple? or !field.nested_form
            nform.visible_fields.each do |f|
              @association << [f.nested_label, field_nested_name(f)]
            end
          end
        end

        @normal + @association
      end

      def configuration_params(&block)
        if block
          @configuration_params = block
        else
          if @configuration_params
            @configuration_params.(self, @show_form.resource)
          elsif @show_form.resource.respond_to? :configuration_params
            @show_form.resource.configuration_params
          else
            nil
          end
        end
      end

      render :configuration do
        params = configuration_params
        view.render(*params) if params
      end

      render :form do |options = nil, &block|
        options = (options || {}).dup.reverse_merge!(@builder_default_options)
        options[:url] ||= path

        view.simple_form_for(@show_form.chain, options) do |simple_form|
          with_builder(simple_form) do
            view.safe_concat render_setup_form
            view.safe_concat(view.capture(self, &block)) if block
          end
        end
      end

      render :setup_form do
        view.form_setup_simple_form(builder) + view.hidden_field_tag(:import_id, @show_form.resource.id)
      end

    end
  end
end


