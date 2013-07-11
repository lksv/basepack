module Lepidlo
  module Controllers
    class Import
      attr_reader :params
      attr_reader :controller
      attr_reader :current_ability
      attr_reader :form

      def initialize(params, controller, form)
        @params = params
        @controller = controller
        @current_ability = controller.current_ability
        @form = form
      end

      def resource_class
        @form.resource_class
      end

      def get(patch = false)
        import_params = params[:import]
        @form.edit_form.resource.klass = resource_class.to_s

        if params[:import_id].present?
          # import selected
          form = @form.show_form
          import_resource = form.resource_class.find(params[:import_id])
          current_ability.authorize!(:show, import_resource) # CanCan
          form.resource = import_resource

          if patch and import_params.present?
            # update import
            current_ability.authorize!(:update, import_resource) # CanCan
            send("import_sanitize_params_#{import_resource.file_type}!", import_params, import_resource)
            if import_resource.update_attributes(controller.edit_form_for(import_resource).permit_params(import_params))
              yield(import_resource)
            end
          end
        end
      end

      def patch(&block)
        get(true, &block)
      end

      def post
        import_params = params[:import]
        if import_params.present?
          # create import
          form = @form.edit_form
          form.resource.assign_attributes(current_ability.attributes_for(:new, form.resource_class))
          form.resource.assign_attributes(form.permit_params(import_params))
          current_ability.authorize!(:create, form.resource) # CanCan
          yield if form.resource.save
        end
      end

      def delete
        import = @form.show_form.resource_class.find(params[:delete_id])
        current_ability.authorize!(:destroy, import) # CanCan
        yield if import.destroy
      end

      def import_sanitize_params_csv!(import_params, import)
        if mapping = import_params[:configuration].try(:[], :mapping)
          options = Hash[form.fields_for_import_as_select_options.map {|o| [o[1], o[1].presence] }]
          import_params[:configuration][:mapping] = Array.wrap(mapping).map {|n| options[n]}
        end
      end

      def import_configuration_csv(form, import)
        # separator
        unless import.configuration[:col_sep]
          col_sep = ','
          import.open_file do |f|
            col_sep = ';' if l = f.gets and l.count(';') > l.count(',')
          end
          import.configuration[:col_sep] = col_sep
        end

        # columns
        row = []
        import.open_file do |f|
          CSV.new(f, col_sep: import.configuration[:col_sep]).each do |r|
            if r.present?
              row = r
              break
            end
          end
        end
        [
          "forms/import_configuration_csv",
          {
            form:           form,
            csv_cols:       row,
            select_options: form.fields_for_import_as_select_options,
            configuration:  import.configuration,
          },
        ]
      end

      def self.import_data_csv(import, resource_class, current_ability)
        mapping = import.configuration[:mapping] || []
        skip_rows = import.num_imported + import.num_errors + 1 # 1==header, if > 1, then import failed and called repeatedly
        idx = 0

        import.open_report do |report|
          if skip_rows == 1
            report << CSV.generate_line(mapping + ["Chyby"], encoding: 'UTF-8')
          end
          import.open_file do |f|
            CSV.new(f, col_sep: import.configuration[:col_sep] || ',').each do |row|
              next if row.blank?
              idx += 1
              next if idx <= skip_rows

              attrs = current_ability.attributes_for(:import, resource_class).dup
              row.each_with_index do |data, i|
                attr = mapping[i]
                attrs[attr] = data if attr.present?
              end
              attrs = Rack::Utils.parse_nested_query(attrs.to_query)

              if attrs.present?
                import.transaction do
                  object = resource_class.new(attrs)
                  object.send(:import, import, current_ability) if object.respond_to? :import
                  object.run_callbacks :import do
                    if object.save
                      import.num_imported += 1
                    else
                      import.num_errors += 1
                      report << CSV.generate_line(row + [object.errors.full_messages.join('; ')], encoding: 'UTF-8')
                    end
                    import.save!
                  end
                end
              end
            end
          end
        end
      end

    end
  end
end

