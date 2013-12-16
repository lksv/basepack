module Basepack
  module Renderable
    extend ActiveSupport::Concern

    module ClassMethods
      def render(name = nil, options = {}, &rendering_block)
        if name.blank?
          render = "render"
          content = options[:content] || "content"
        else
          render = "render_#{name}"
          content = options[:content] || "content_for_#{name}"
        end

        var = "@#{content}".to_sym
        render_bang = "#{render}!"

        define_method content do |&block|
          # hack - view.capture doesn't work for Haml if not called on block with original binding
          params = block.parameters
          if params.present? and params.last[0] == :block
            instance_variable_set(var, [block, eval("proc {|c, s, a, b| c.(s, *a, &b)}", block.binding)])
          else
            instance_variable_set(var, block)
          end
        end

        define_method render_bang, &rendering_block

        define_method render do |*args, &block|
          if cont_block = instance_variable_get(var)
            if cont_block.is_a? Array
              view.capture(cont_block[0], self, args, block, &cont_block[1])
            else
              view.capture(self, *args, &cont_block)
            end
          else
            send(render_bang, *args, &block)
          end
        end
      end
    end
  end
end

