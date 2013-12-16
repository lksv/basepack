module Basepack
  module Forms
    class Diff < Forms::Edit
      attr_reader :form2
      attr_accessor :path

      def initialize(factory, chain1, chain2, options = {})
        super(factory, chain1, options)
        @path = options[:path]
        @form2 = Basepack::Forms::Show.new(factory, chain2)

        @compare = {}
        compare '*' do |f1, f2|
          if f1.association?
            a1, a2 = Array.wrap(f1.value).compact, Array.wrap(f2.value).compact
            a1, a2 = a2, a1 if a1.size < a2.size
            a1.zip(a2).all? {|v1, v2| v2 ? v1.same_as?(v2) : false }
          else
            f1.value.presence == f2.value.presence
          end
        end
      end

      def build_from_factory
        factory.build_form(@form2)
        factory.build_form(self)
      end

      def resource2
        @form2.resource
      end

      def field2(name, attributes = nil)
        if field(name)
          @form2.field(name, attributes)
        else
          nil
        end
      end

      def visible_field2(name)
        visible_field(name) ? @form2.visible_field(name) : nil
      end

      def compare(field_name, &block)
        if block_given?
          @compare[field_name] = block
        else
          @compare[field_name]
        end
      end

      def field_show_values(name, &block)
        f1 = field(name)
        f2 = field2(name)
        f1.pretty_value = yield(f1, f2)
        f2.pretty_value = yield(f2, f1)
      end

      def default_partial
        'forms/diff'
      end

    end
  end
end
