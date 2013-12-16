module Basepack
  module Forms
    class Base
      include Basepack::Renderable

      attr_reader   :groups
      attr_reader   :factory
      attr_reader   :resource_class
      attr_reader   :association_chain
      attr_accessor :resource
      attr_accessor :view
      attr_accessor :partial
      attr_reader   :nested_in

      def initialize(factory, chain, options = {})
        @factory     = factory
        @fields_hash = {}
        @groups      = []
        @nested_in   = options[:nested_in]

        chain = Array.wrap(chain)
        @association_chain = chain[0...-1].freeze

        if chain.last.is_a? Class
          @resource_class = chain.last
        else
          @resource = chain.last
          @resource_class = @resource.class
        end
      end

      def build_from_factory
        factory.build_form(self)
      end

      def new_form(*args)
        form = factory.new_form(*args)
        form.view = view
        if configure_nested_form = form.nested_in.try(:configure_nested_form)
          form.configure(&configure_nested_form)
        end
        form
      end

      def configure(&block)
        yield(self)
        self
      end

      def label
        @label ||= resource_class.model_name.human
      end

      def label_plural
        @label_plural ||= resource_class.model_name.human(count: 'other', default: label.pluralize)
      end

      def chain
        @association_chain + [resource]
      end

      def chain_with_class
        @association_chain + [resource_class]
      end

      def resource
        @resource ||= resource_class.new # TODO - nested_in.build_resource
      end

      def new_record?
        !@resource or @resource.new_record?
      end

      def inverse_of_nested_in?(field) # TODO remove and should be automatical (test in visible_fields or in visible?)
        field.inverse_of_nested_in?
      end

      def field_names
        @fields_hash.keys
      end

      def fields
        @fields_hash.values
      end

      def fields_hash
        @fields_hash.dup
      end

      def visible_fields
        @fields_hash.values.find_all {|f| f.visible? }
      end

      def has_field?(name)
        @fields_hash.has_key? name
      end

      def field(name, delegate_or_attributes = nil)
        if delegate_or_attributes or block_given?
          field = @fields_hash[name]
          if field
            field.update_attributes(delegate_or_attributes) unless delegate_or_attributes.nil?
          else
            field = factory.new_field(name, self, delegate_or_attributes)
          end
          yield(field) if block_given?
          @fields_hash[name] = field
        else
          @fields_hash[name]
        end
      end

      def visible_field(name)
        field = @fields_hash[name]
        field && field.visible? ? field : nil
      end

      def hide_field(field_name)
        @fields_hash[field_name].try :visible=, false
      end

      def hide_fields(*field_names)
        field_names.each {|f| hide_field(f)}
      end

      def show_fields(*field_names)
        field_names.each {|name| @fields_hash[name].try :visible, true }
      end

      def group(attributes = nil)
        group = factory.new_group(self, attributes)
        yield(group) if block_given?
        @groups << group
        group
      end

      def default_group
        @groups.first
      end

      def visible_groups
        groups.find_all {|g| g.field_names.present? }
      end

      render do
        view.render @partial || default_partial, form: self
      end

      def default_partial
      end

      def render_field(field)
        field.render
      end

      def render_field!(field)
      end

      def content_for_field(field_name, &block)
        field(field_name) do |f|
          f.content(&block)
        end
      end

      def path
        view.url_for(chain)
      end

      def permit_params(params)
        sanitize_params(params).permit!
      end

      def sanitize_params(params)
        new_params = params.dup
        allowed = [ 
          # :id,   #FIXME: checkme: has to be not allowed by default, but what about nested forms?
          :_destroy 
        ]

        visible_fields.each do |f|
          next if f.read_only? or f.inverse_of_nested_in?

          f.parse_input(new_params)

          f.allowed_methods.each do |m|
            if f.type == :serialized or (new_params[m].is_a?(Array) or new_params[m].is_a?(Hash)) ^ !f.multiple?
              allowed << m
            end
          end

          if nform = f.nform and nparams = new_params[f.method_name]
            new_params[f.method_name] = case nparams
            when Array
              nparams.map {|p| p.is_a?(Hash) ? nform.sanitize_params(p) : p.to_s}
            when Hash
              if f.multiple?
                Hash[nparams.map {|k, p| [k, p.is_a?(Hash) ? nform.sanitize_params(p) : p.to_s] }]
              else
                allowed << f.method_name
                nform.sanitize_params(nparams)
              end
            else
              nparams
            end
          end
        end

        unpermitted = new_params.slice!(*allowed)
        if unpermitted.present?
          ActiveSupport::Notifications.instrument("unpermitted_parameters.action_controller", keys: unpermitted.keys)
        end

        new_params
      end

      def with_resource(resource, *args, &block)
        orig_resource, @resource = @resource, resource
        begin
          yield(resource, *args)
        ensure
          @resource = orig_resource
        end
      end

      def inspect
        "#<#{self.class.name}[#{resource_class.name}] #{field_names}>"
      end

      # use more lookup paths for translations
      def translate(resource, action, subaction = "menu")
        Utils.translate(resource, action, subaction)
      end

    end
  end
end

