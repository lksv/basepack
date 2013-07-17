module Lepidlo
  module Import
    module Controller
      extend ActiveSupport::Concern

      included do
        class_attribute :import_class
        helper_method :import_form_for
        self.import_class ||= "Import".constantize rescue nil
        import_action :import
      end

      module ClassMethods
        def import_action(name, actions_class = Lepidlo::Import::Actions)
          name = name.to_sym
          custom_actions collection: [name]
          name_bang = "#{name}!"

          # [GET,POST,PATCH,DELETE] /resources/#{name}
          define_method name_bang do |&block|
            @title_params = [[resource_class, "Import"]]

            authorize!(name, resource_class) # CanCan

            @import_actions = actions_class.new(self, import_form)
            if request.get?
              @import_actions.get
            elsif request.patch?
              @import_actions.patch do |import_resource|
                # run import
                import_resource.import_data(current_ability) if import_resource.state == "not_started"
                redirect_to import_resources_path(import_id: import_resource.id),
                  notice: message_edit_done(import_form.show_form.label)
              end
            elsif request.post?
              @import_actions.post do
                redirect_to import_resources_path(import_id: import_form.edit_form.resource.id),
                  notice: message_new_done(import_form.edit_form.label)
              end
            elsif request.delete?
              @import_actions.delete do
                redirect_to import_resources_path,
                  notice: message_destroy_done(import_form.edit_form.label)
              end
            end
          end

          define_method name do
            send(name_bang)
          end

          name_form = "#{name}_form"
          name_form_bang = "#{name}_form!"
          var = "@#{name}_form".to_sym

          define_method name_form_bang do |&block|
            unless form = instance_variable_get(var)
              form = import_form_for(chain_with_class)
              form.configure(&block) if block
              form.configuration_params do |frm, import|
                import_actions = actions_class.new(self, frm)
                method = "import_configuration_#{import.file_type}"
                import_actions.send(method, import) if import_actions.respond_to?(method)
              end
              instance_variable_set(var, form)
            end
            form
          end

          helper_method name_form

          define_method name_form do
            send(name_form_bang)
          end

        end
      end

      def import_form_for(class_or_chain, options = {})
        klass = Array.wrap(class_or_chain).last
        form_factory_rails_admin(:import, Lepidlo::Forms::Import, class_or_chain,
           action_name: options[:action_name] || action_name.to_sym,
           edit_form:   edit_form_for(import_class),
           show_form:   show_form_for(import_class),
           list_form:   list_form_for(query_form_for(import_class, import_class.where(klass: klass))))
      end

    end
  end
end

