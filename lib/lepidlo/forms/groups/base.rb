module Lepidlo
  module Forms
    module Groups
      class Base
        include Lepidlo::Delegation

        delegate_attrs :name, :label, :help

        attr_reader :form, :delegate
        attr_accessor :field_names

        def initialize(form, delegate_or_attributes = nil)
          @form = form
          @field_names = []
          update_attributes(delegate_or_attributes)
        end

        def update_attributes(delegate_or_attributes)
          if delegate_or_attributes.is_a? Hash
            delegate_or_attributes.each do |a, v|
              send("#{a}=", v)
            end
          else
            @delegate = delegate_or_attributes
          end
        end

        def field(name, delegate_or_attributes = nil, &block)
          field = @form.field(name, delegate_or_attributes, &block)
          @field_names << name if field and !@field_names.include?(name)
          field
        end

        def content_for_field(field_name, &block)
          field(field_name) do |f|
            f.content(&block)
          end
        end

        def fields
          @field_names.map {|f| @form.field(f)}.compact
        end

        def visible_fields
          @field_names.map {|f| @form.visible_field(f)}.compact
        end

        def remove
          @form.groups.delete self
        end

        def values
          result = {}
          visible_fields.each {|f| result[f.name] = f.value}
          result
        end

        def values_without_blank
          result = {}
          visible_fields.each do |f|
            val = f.value.presence
            result[f.name] = val unless val.nil?
          end
          result
        end

      end
    end
  end
end

