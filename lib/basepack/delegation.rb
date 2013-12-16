module Basepack
  module Delegation
    extend ActiveSupport::Concern

    module ClassMethods
      def delegate_attrs(*attrs_names)
        options = attrs_names.last.is_a?(Hash) ? attrs_names.pop : {}
        to = options[:to] || :delegate

        attrs_names.each do |attr|
          if attr[-1] == "?"
            writter = attr[0...-1]
            define_method attr do
              send(writter)
            end
          else
            writter = attr
          end

          var = "@#{writter}".to_sym
          default = "#{writter}!".to_sym
          delegated = "#{writter}_delegated".to_sym

          attr_writer writter

          define_method writter do |&block|
            if block
              instance_variable_set(block)
            else
              if instance_variable_defined?(var)
                val = instance_variable_get(var)
                val.is_a?(Proc) ? instance_eval(&val) : val
              else
                send(default)
              end
            end
          end

          define_method delegated do
            d = send(to)
            d.respond_to?(attr) ? d.public_send(attr) : nil
          end

          define_method default do
            send(delegated)
          end
        end
      end

      def attr_default(attr, if_args = [], &block)
        delegated = "#{attr}_delegated".to_sym
        if_args = if_args.map {|a| "@#{a}".to_sym }

        define_method "#{attr}!" do
          val = send(delegated)
          if val.nil? or if_args.any? {|a| instance_variable_defined?(a) }
            instance_eval(&block)
          else
            val # no argument redefined, return delegate
          end
        end
      end
    end
  end
end

