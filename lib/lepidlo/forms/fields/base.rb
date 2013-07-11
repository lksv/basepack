module Lepidlo
  module Forms
    module Fields
      class Base
        include Lepidlo::Delegation
        include Lepidlo::Renderable

        delegate_attrs :type, :method_name, :label, :value, :pretty_value, :help,
          :type_css_class, :css_class, :associated_model_config, :polymorphic?, :association,
          :visible?, :active?, :read_only?, :enum, :abstract_model, :export_value,
          :filterable?, :queryable?, :searchable, :sortable, :sort_reverse, :virtual?,
          :options_source, :options_source_params, :partial, :partial_show,
          :view_helper, :required?, :html_attributes, :nested_form, :inverse_of, :multiple?,
          :associated_primary_key, :optional?, :editable?, :foreign_key, :allowed_methods,
          :errors, :cache_method, :delete_method, :orderable, :inline_add, :inline_edit,
          :html_default_value, :js_plugin_options,
          :css_location, :js_location, :config, :assets, :config_options, :config_js, :base_location, :location

        ASSOC_TYPES = {
          :belongs_to_association              => true,
          :has_and_belongs_to_many_association => true,
          :has_many_association                => true,
          :has_one_association                 => true,
          :polymorphic_association             => true,
        }

        attr_reader :name, :form
        attr_reader :delegate

        def initialize(name, form, delegate_or_attributes = nil)
          @name = name
          @form = form
          update_attributes(delegate_or_attributes)
        end

        def copy(attributes = nil)
          field = self.class.new(name, form, self)
          field.update_attributes(attributes) if attributes.is_a? Hash
          field
        end

        attr_default :visible do
          true
        end

        attr_default :method_name do
          name
        end

        attr_default :foreign_key do
          "#{name}_id".to_sym
        end

        attr_default :queryable, [:virtual] do
          !virtual?
        end

        attr_default :filterable, [:searchable] do
          !!searchable
        end

        def association?
          !!ASSOC_TYPES[type]
        end

        def update_attributes(delegate_or_attributes)
          if delegate_or_attributes.is_a? Hash
            delegate_or_attributes.each do |a, v|
              send("#{a}=", v)
            end
          else
            #raise ArgumentError, "Invalid delegate #{delegate_or_attributes}" unless
            #  delegate_or_attributes.respond_to? :type
            @delegate = delegate_or_attributes
          end
        end

        def view
          form.view
        end

        def enum_options
          if type == :enum # TODO - into own class
            if form.resource_class.respond_to? :enumerized_attributes
              # enumerize
              values = form.resource_class.enumerized_attributes[method_name].try(:values)
              values.map {|val| [val.value, val.text]}
            else
              enum.map {|a| a.reverse }
            end
          end
        end

        render do
          form.render_field!(self)
        end

        def value
          form.resource.send(name)
        end

        def configure_nested_form(&block)
          if block
            @configure_nested_form = block
          else
            @configure_nested_form
          end
        end

        def parse_input(params)
          @delegate.parse_input(params) if @delegate
        end

        def nform
          if association? and !polymorphic?
            @nform ||= form.new_form(associated_model_config.abstract_model.model, nested_in: self)
          else
            nil
          end
        end

        def inverse_of_nested_in?
          (nested_in = form.nested_in) and nested_in.name == inverse_of and
            nested_in.abstract_model.model == associated_model_config.abstract_model.model
        end

        def nested_label
          form.nested_in ? "#{form.nested_in.nested_label}: #{label}" : label
        end

      end
    end
  end
end
