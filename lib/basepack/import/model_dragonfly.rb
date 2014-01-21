module Basepack
  module Import
    module ModelDragonfly
      extend ActiveSupport::Concern

      included do
        attr_accessor :current_ability

        has_many :importables, inverse_of: :import, dependent: :destroy, class_name: 'Basepack::ImportImportable'

        dragonfly_accessor :file
        dragonfly_accessor :report

        serialize :configuration, Hash

        validates :klass,  presence: true
        validate :validate_klass_is_model

        validates :file,  presence: true
        validates_property :mime_type, of: [:file, :report], in: Basepack::Settings.import.mime_types, case_sensitive: false
        validates :state, presence: true, inclusion: { in: Basepack::Settings.import.state_types.map { |t| t.last } }
        validates :action_name, :num_errors, :num_imported, presence: true

        rails_admin do
          configure :file_name do
            pretty_value do
              bindings[:view].link_to(value, bindings[:object].file.url)
            end
          end
          configure :file_size do
            pretty_value do
              value.to_s(:human_size)
            end
          end
          configure :report_name do
            pretty_value do
              bindings[:object].report ? bindings[:view].link_to(value, bindings[:object].report.url) : nil
            end
          end
          configure :num_errors do
            pretty_value do
              bindings[:object].report ? bindings[:view].link_to(value, bindings[:object].report.url) : value.to_s
            end
          end
          configure :num_imported do
            pretty_value do
              if bindings[:object].klass
                klass = bindings[:object].importable_class
                assoc_name = Basepack::Settings.import.association_name
                if assoc_name and klass.reflect_on_association(assoc_name)
                  bindings[:view].link_to(
                    value,
                    bindings[:view].main_app.polymorphic_path(klass,
                      "f[#{assoc_name}_id_eq]" => bindings[:object].id)
                  )
                else
                  value.to_s
                end
              else
                value.to_s
              end
            end
          end

          query do
            sort_by :created_at
          end

          show do
            field :file_name
            field :file_mime_type
            field :file_size
            field :report_name
            field :num_errors
            field :num_imported
            field :state
            field :created_at
          end

          list do
            field :file_name
            field :file_size
            field :num_errors
            field :num_imported
            field :state
            field :created_at
          end

          update do
            field :state, :hidden
            field :configuration
          end

          edit do
            field :file
          end
        end
      end

      module ClassMethods
        def state_enum
          Basepack::Settings.import.state_types
        end
      end

      def file_type
        case file.try(:mime_type)
        when "text/csv", "text/plain"
          :csv
        else
          :unknown
        end
      end

      def open_file(encoding_from = nil, &block)
        encoding =
          (encoding_from and encoding_from.upcase != 'UTF-8') ?
          "r:#{encoding_from}:utf-8" : "rb:ASCII-8BIT"
        File.open(file.path, encoding, &block)
      end

      def open_report(&block)
        File.open(report.path, "a:utf-8", &block)
      end

      def validate_klass_is_model
        begin
          c = klass.constantize
          raise NameError unless c.ancestors.include? ActiveRecord::Base
          false
        rescue NameError
          errors.add(:klass, "is not known model!")
          true
        end
      end

      def importable_class
        klass.constantize
      end

      def start_processing(&block)
        import = self
        unless import.state == "finished"
          unless import.state == "processing"
            name = "report-#{import.id}.csv"
            data = ""
            data.define_singleton_method(:original_filename) { name }
            import.report = data
            import.state = "processing"
            import.save!
            import = self.class.find(import.id) # reload report path
          end
          yield(import)
          import.update_attributes!(state: "finished")
        end
      end

      def import_data(current_ability)
        start_processing do |import|
          import.current_ability = current_ability
          import.send("import_data_#{import.file_type}")
        end
      end

      def import_data_csv
        import = self
        ability_attributes = current_ability.attributes_for(:import, importable_class)
        mapping = import.configuration[:mapping] || []
        use_blanks = import.configuration[:blank_vals] == 'use'
        skip_rows = import.num_imported + import.num_errors + 1 # 1==header, if > 1, then import failed and called repeatedly
        idx = 0

        import.open_report do |report|
          if skip_rows == 1
            report << CSV.generate_line(mapping + ["Chyby"], encoding: 'UTF-8')
          end
          import.open_file(import.configuration[:encoding_from] || 'UTF-8') do |f|
            CSV.new(f, col_sep: import.configuration[:col_sep] || ',').each do |row|
              next if row.blank?
              idx += 1
              next if idx <= skip_rows

              attrs = ability_attributes.dup
              row.each_with_index do |data, i|
                attr = mapping[i]
                attrs[attr] = data if attr.present? and (data.present? or use_blanks)
              end

              import_attributes(Rack::Utils.parse_nested_query(attrs.to_query)) do |object|
                unless save_object(object)
                  report << CSV.generate_line(row + [object.errors.full_messages.join('; ')], encoding: 'UTF-8')
                end
              end
            end
          end
        end
      end

      def import_attributes(attrs, &block)
        if attrs.present?
          transaction do
            model = importable_class

            begin
              object = model.try(:find_or_initialize_for_import, attrs) ||
                       Basepack::Import::Importable.find_or_initialize_for_import(model, attrs)
            rescue ActiveRecord::RecordNotFound => e # error in finding nested attributes
              object = model.new
              object.errors[:base] << e.message
            end

            if object.respond_to?(:around_import)
              object.around_import(self) { yield(object) }
            else
              yield(object)
            end
            save!
          end
        end
      end

      def save_object(object)
        status = object.errors.empty? ? object.save : false
        if status
          self.num_imported += 1
          self.importables.build(importable: object)
        else
          self.num_errors += 1
        end
        status
      end
    end
  end
end

