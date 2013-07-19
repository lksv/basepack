require "lepidlo/engine"
require 'lepidlo/version'
require 'lepidlo/sections/query'
require 'lepidlo/sections/import'

module Lepidlo
  def self.setup

    Array.class_eval do
      def to_csv(schema = {}, options = {})
        if all? {|o| o.respond_to?(:to_csv)}
          map {|o| o.to_csv(schema, options) }.join
        else
          CSV.generate_line(self, options.reverse_merge(encoding: 'UTF-8'))
        end
      end
    end

    ActiveRecord::Base.class_eval do
      def to_label
        send(Lepidlo::Settings.to_label_methods.find {|m| respond_to?(m)} || :to_s)
      end

      def to_details_label
        @view ||= begin
          view = ActionView::Base.new(ActionController::Base.view_paths, {})
          view.extend ApplicationHelper
          view
        end
        begin
          @view.render(partial: "#{self.class.model_name.route_key}/details_label", layout: false, locals: { resource: self } ).html_safe
        rescue ActionView::MissingTemplate
          to_label
        end
      end

      def labelize(&block)
        if new_record?
          ""
        else
          yield.to_s.truncate(40, :separator => ' ')
        end
      end

      def to_csv(schema = {}, options = {})
        schema = { include_root_in_json: false }.reverse_merge!(schema)
        values = Lepidlo.map_value_csv(as_json(schema))
        CSV.generate_line(values, options.reverse_merge(encoding: 'UTF-8'))
      end

      #def self.ransackable_attributes(auth_object = nil)
      #  authorizer = active_authorizer[:default]
      #  super(auth_object).reject {|a| a != 'id' && authorizer.deny?(a)}
      #end

      #def self.ransackable_associations(auth_object = nil)
      #  authorizer = active_authorizer[:default]
      #  super(auth_object).reject {|a| authorizer.deny?("#{a}_id") && authorizer.deny?("#{a}_attributes")}
      #end
    end

    ActionController::Renderers.add :csv do |obj, options|
      filename = options[:filename] || 'data'
      str = obj.respond_to?(:to_csv) ? obj.to_csv : obj.to_s
      send_data str, :type => Mime::CSV, :disposition => "attachment; filename=#{filename}.csv"
    end

    Ransack::Search.class_eval do
      def errors
        @errors_patch ||= {}
      end

      attr_accessor :custom_filters
    end

    RailsAdmin::Config::Fields::Association.class_eval do
      alias pretty_value! pretty_value

      register_instance_option :pretty_value do
        if RailsAdmin::ApplicationController === bindings[:controller]
          pretty_value!
        else
          bindings[:view].form_field_show_association(self)
        end
      end

      register_instance_option :options_source do
        begin
          bindings[:view].url_for([:options, associated_model_config.abstract_model.model])
        rescue
            Rails.logger.debug <<-MESSAGE.strip_heredoc


            [Lepidlo] Please add routes for '#{associated_model_config.abstract_model.model}' - url_for([:options, #{associated_model_config.abstract_model.model}]) failed

            MESSAGE
          "/#{associated_model_config.abstract_model.model.name.parameterize}-options-url-not-exists"
        end
      end

      register_instance_option :options_source_params do
        {}
      end

      register_instance_option :partial_show do
        nil
      end
    end

    RailsAdmin::Config::Fields::Base.class_eval do
      alias export_value! export_value

      register_instance_option :export_value do
        formatted_value
      end
    end

    RailsAdmin::Config::Fields::Types::Datetime.class_eval do
      alias export_value! export_value

      register_instance_option :export_value do
        unless (time = value).nil?
          I18n.l(time, format: "%d.%m.%Y %T")
        else
          ""
        end
      end
    end

    RailsAdmin::Config::Fields::Types::Time.class_eval do
      register_instance_option :export_value do
        export_value!
      end
    end

    #RailsAdmin::Config::Fields::Types::Enum.class_eval do
    #  register_instance_option :pretty_value do
    #    v = bindings[:object].send(name)
    #    v ? v.text : ' - '
    #  end
    #end

    #RailsAdmin::Adapters::ActiveRecord.class_eval do
    #  private

    #  alias build_statement! build_statement

    #  def build_statement(column, type, value, operator)
    #    result = build_statement!(column, type, value, operator)
    #    return unless result.present?

    #    case type
    #    when :enum
    #      if operator == '_blank' || value == '_blank'
    #        result = ["(#{column} IS NULL)"]
    #      elsif operator == '_present' || value == '_present'
    #        result = ["(#{column} IS NOT NULL)"]
    #      else
    #        in_values = {}
    #
    #        if enum_attrs = model.enumerized_attributes[column[/([^.]+)$/, 1].to_sym]
    #          enum_values = enum_attrs.values

    #          values = Array.wrap(value).each do |val|
    #            enum_values.each do |e_val| 
    #              if e_val == val or e_val.value == val or e_val.text.downcase.include?(val.downcase)
    #                in_values[e_val.value] = true
    #              end
    #            end
    #          end
    #        end

    #        result = in_values.empty? ? nil : ["(#{column} IN (?))", in_values.keys]
    #      end
    #    end

    #    return result
    #  end
    #end
  end

  def self.map_value_csv(value)
    case value
    when Hash
      value.map {|k, v| map_value_csv(v) }.flatten
    when Array
      arr = value.map {|v| Array.wrap(map_value_csv(v)) }
      arr.empty? ? arr : arr.first.zip(*arr[1..-1]).map {|a| a.join(',')}
    else
      value
    end
  end

end
