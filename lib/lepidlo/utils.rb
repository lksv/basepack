module Lepidlo
  module Utils
    def self.model_config(resource_class)
      model_config = RailsAdmin.config(resource_class)
      raise ArgumentError.new("Model #{resource_class.inspect} not known by RailsAdmin") unless model_config
      raise ArgumentError.new("Model #{resource_class.inspect} excluded from RailsAdmin") if model_config.excluded?
      model_config
    end

    def self.detect_models
      ([Rails.application] + Rails::Engine::Railties.engines).map do |app|
        app.paths['app/models'].to_a.map do |load_path|
          Dir.glob(app.root.join(load_path)).map do |load_dir|
            Dir.glob(load_dir + "/**/*.rb").map do |filename|
              # app/models/module/class.rb => module/class.rb => module/class => Module::Class
              filename.reverse.chomp("#{app.root.join(load_dir)}/".reverse).reverse.chomp('.rb').camelize
            end
          end
        end
      end.flatten
    end

    def self.query_from_params(scope, params, auth_object = nil, config = nil)
      config ||= model_config(scope.klass)
      scope = paginate(query(scope, params, config), params)
      filter(scope, params, config, auth_object)
    end

    def self.filter(scope, params, config, auth_object = nil)
      filter = params[:f].is_a?(Hash) ? params[:f] : {}
      custom_filters = []
      error = nil

      if params[:ql].present?
        begin
          filter = filter.merge(FilterQL.new.parse(params[:ql]))
        rescue FilterQL::ParseError => e
          error = e.message
        end
      end

      # default sorting
      #
      if filter[:s].blank? and config.query.sort_by
        sort_by = config.query.sort_by.to_sym
        if field = config.query.fields.find {|f| f.name == sort_by }
          columns = field_sortable_columns(field)
          if columns.present?
            filter = filter.merge(s: Hash[columns.map.with_index do |c, i|
              [ i.to_s, { name: c[0], dir: c[1] ^ config.query.sort_reverse? ? 'desc' : 'asc' } ]
            end])
          end
        end
      end

      # custom filters
      #
      filter.each do |k, v|
        if k == "c"
          # {"c"=>{"28054"=>{"a"=>{"0"=>{"name"=>"tag"}}, "p"=>"cont", "v"=>{"0"=>{"value"=>"test"}}}}
          #
          v.each_value do |cond|
            f = [cond["a"]["0"]["name"], cond["p"] || 'eq', cond["v"].try(:[], "0").try(:[], "value")]
            method = cond["p"] ? "filter_#{f[0]}_#{f[1]}" : "filter_#{f[0]}"
            if scope.klass.respond_to? method
              scope = scope.klass.send(method, scope, f[2], auth_object)
              custom_filters << f
            else
              nil
            end
          end
        elsif k =~ /\A(.*)_((?:(?:does_)?not_)?[a-z]+)\z/
          atr = $1
          predicate = $2
          method = "filter_#{k}".sub(/_eq\z/, '')
          if scope.klass.respond_to? method
            scope = scope.klass.send(method, scope, v, auth_object)
            custom_filters << [atr, predicate, v]
          else
            Rails.logger.warn("Unknown filter #{method.inspect} with params #{v.inspect}.")
            nil
          end
        end
      end

      resource_filter = scope.ransack(filter, search_key: :f, auth_object: auth_object)
      resource_filter.errors[:base] = [error] if error
      resource_filter.custom_filters = custom_filters
      scope = resource_filter.result(distinct: true)
      [resource_filter, scope]
    end

    def self.paginate(scope, params)
      scope = scope.page(params[:page].presence || 1)
      scope = scope.per(params[:per].presence) if params[:per].presence
      scope
    end

    def self.sort(scope, params, config)
      scope.order()
    end

    def self.query(scope, params, config)
      query = params[:query]

      if query.present?
        or_arel = []
        model = config.abstract_model.model
        object = nil
        dquery = query.downcase

        if model.respond_to?(:default_query)
          return scope.merge(model.send(:default_query, query))
        end

        config.query.fields.select(&:queryable?).map do |field|
          field.searchable_columns.each do |column_infos|
            column = model.arel_table[column_infos[:column][/([^.]+)$/, 1].to_sym]

            case column_infos[:type]
            when :integer
              begin
                or_arel << column.eq(Integer(query))
              rescue ArgumentError
              end
            when :decimal, :float
              begin
                or_arel << column.eq(Float(query))
              rescue ArgumentError
              end
            when :string, :text
              or_arel << column.matches("%#{query}%")
            when :boolean
              if Ransack::Constants::TRUE_VALUES.include? query
                or_arel << column.eq(true)
              elsif Ransack::Constants::FALSE_VALUES.include? query
                or_arel << column.eq(false)
              end
            when :date
              begin
                or_arel << column.eq(Time.zone.parse(query).to_date)
              rescue ArgumentError, NoMethodError
              end
            when :datetime, :timestamp
              begin
                date = Time.zone.parse(query).to_datetime
                if date.midnight - date == 0
                  or_arel << column.gteq(date).and(column.lt(date.advance(:days => 1)))
                elsif date.sec_fraction == 0
                  if date.sec == 0
                    or_arel << column.gteq(date).and(column.lt(date.advance(:minutes => 1)))
                  else
                    or_arel << column.gteq(date).and(column.lt(date.advance(:seconds => 1)))
                  end
                else
                  or_arel << column.eq(date)
                end
              rescue ArgumentError, NoMethodError
              end
            when :enum
              values = nil
              if model.respond_to? :enumerized_attributes
                # enumerize
                if enum_attrs = model.enumerized_attributes[column.name]
                  values = enum_attrs.values.map do |e_val|
                    e_val.value if e_val == query or e_val.value == query or e_val.text.downcase.include?(dquery)
                  end.compact
                end
              else
                enum_method = "#{column.name}_enum"
                if model.respond_to?(enum_method)
                  options = model.send(enum_method)
                else
                  object ||= model.new
                  options = object.try(enum_method)
                end
                values = options.map do |o|
                  o[1] if o[0].to_s.downcase.include?(dquery) or o[1].to_s.downcase.include?(dquery)
                end.compact if options
              end
              or_arel << column.in(values) if values.present?
            end
          end
        end

        scope = or_arel.present? ? scope.where(or_arel.map {|a| a.to_sql}.join(' OR ')) : scope.where("0") # none
      end

      scope
    end

    def self.field_sortable_columns(field)
      sort_reverse = field.sort_reverse
      Array.wrap(field.sortable).map do |sort|
        if sort == true
          # use field for sorting
          [ field.name.to_s, sort_reverse ]
        elsif sort == false
          # asked field is not sortable
          nil
        elsif (sort.is_a?(String) || sort.is_a?(Symbol)) and sort.to_s.include?('.')
          # just provide sortable, don't do anything smart
          [ sort.to_s, sort_reverse ]
        elsif sort.is_a?(Hash)
          # just join sortable hash, don't do anything smart
          [ "#{sort.keys.first}_#{sort.values.first}", sort_reverse ]
        else
          if sort.is_a? Array
            sort, order = sort
          else
            order = sort_reverse
          end
          [
            field.association? ? "#{field.associated_model_config.abstract_model.table_name}_#{sort}" : sort.to_s,
            order
          ]
        end
      end.compact
    end
  end
end

