# encoding: UTF-8
module Lepidlo
  class BaseController < InheritedResources::Base
    respond_to :html
    with_role :default # InheritedResources
    defaults route_prefix: nil
    check_authorization # CanCan

    helper_method :resource_config, :return_to_path, :collection_action?,
                  :chain, :title_params, :resource_filter,
                  :build_resource,
                  :query_params,
                  :list_form, :show_form, :query_form, :edit_form, :export_form,
                  :list_form_for, :show_form_for, :query_form_for, :edit_form_for, :diff_form_for, :export_form_for

    custom_actions collection: [:options, :query, :export]

    def index(options={}, &block)
      block ||= proc do |format|
        format.html do
          render :index # index is also called from query action
        end

        format.json do
          schema = export_form.schema_from_params(params[:schema])
          send_export_data(header: '[', footer: ']') do |object, i|
            "#{',' if i > 0}#{object.to_json(schema)}"
          end
        end

        format.xml do
          schema = {skip_instruct: true}.reverse_merge(export_form.schema_from_params(params[:schema]))
          send_export_data(
            header: %Q{<?xml version="1.0" encoding="UTF-8"?>\n<#{resource_class.model_name.plural} type="array">\n},
            footer: %Q{</#{resource_class.model_name.plural}>}
          ) do |object, i|
            object.to_xml(schema)
          end
        end

        format.csv do
          form = export_form
          fields = form.fields_from_params(params[:schema])
          csv_options = params[:csv_options] || {}
          options = {encoding: 'UTF-8', col_sep: csv_options[:col_sep].presence || Lepidlo::Settings.export.default_col_sep}
          header = csv_options[:skip_header] == 'true' ? '' : CSV.generate_line(form.csv_header(fields), options)

          send_export_data(header: header) do |object, i|
            CSV.generate_line(form.csv_row_for_resource(object, fields), options)
          end
        end
      end
      super(options, &block)
    end
    alias :index! :index

    def update(options={}, &block)
      super(options.reverse_merge(notice: message_edit_done), &block)
    end
    alias :update! :update

    def create(options={}, &block)
      super(options.reverse_merge(notice: message_new_done), &block)
    end
    alias :create! :create

    def destroy(options={}, &block)
      super(options.reverse_merge(notice: message_destroy_done), &block)
    end
    alias :destroy! :destroy

    def options(options={})
      primary_key = resource_class.primary_key
      response = (options[:collection] || collection).map do |object|
        {
          :id   => object.send(primary_key),
          :text => ERB::Util.html_escape(object.to_details_label),
        }
      end
      render :json => response
    end
    alias :options! :options

    # [GET,POST] /resources/query
    def query
      filter_class_name = Lepidlo::Settings.filters.model_name
      if filter_class_name.present? and params[:filter_name].present?
        filter_class = filter_class_name.constantize
        filter = filter_class.new(
          name:         params[:filter_name],
          filter:       params[:ql] || query_form.conditions_to_ql,
          filter_type:  resource_class.to_s
        )
        filter.assign_attributes(current_ability.attributes_for(:create, filter_class))
        if filter.save
          flash.now[:notice] = message_new_done(Lepidlo::Utils.model_config(filter_class).label)
        else
          flash.now[:error] = "Chyba při ukládání filtru: #{filter.errors.full_messages.join('. ')}"
        end
      end

      if request.xhr?
        render partial: "query"
      else
        index
      end
    end
    alias :query! :query


    # [GET,POST] /resources/export
    def export
      if format = params[:json] && :json || params[:csv] && :csv || params[:xml] && :xml
        request.format = format
        index
      else
        render
      end
    end
    alias :export! :export

    def list_form_for(query_form)
      form_factory_rails_admin(:list, Lepidlo::Forms::List, query_form.chain_with_class, query_form: query_form)
    end

    def show_form_for(resource_or_chain)
      form_factory_rails_admin(:show, Lepidlo::Forms::Show, resource_or_chain)
    end

    def query_form_for(class_or_chain, scope, options = {})
      Lepidlo::Forms::Factories::QueryRailsAdmin.new(view_context).new_form(
        class_or_chain,
        { scope: scope }.reverse_merge!(options.reverse_merge(params: params, auth_object: current_ability))
      )
    end

    def edit_form_for(resource_or_chain)
      res = Array.wrap(resource_or_chain).last
      section = (res.is_a?(Class) or res.new_record?) ? :create : :update
      form_factory_rails_admin(section, Lepidlo::Forms::Edit, resource_or_chain)
    end

    def diff_form_for(resource, resource2) # resource or chain
      form_factory_rails_admin(:show, Lepidlo::Forms::Diff, resource, resource2)
    end

    def export_form_for(query_form)
      form_factory_rails_admin(:export, Lepidlo::Forms::Export, query_form.chain_with_class, query_form: query_form)
    end

    def filters
      collection #just for authorize resource
      redirect_to polymorphic_path(Lepidlo::Settings.filters.model_name.constantize, 'f[filter_type_eq]' => resource_class)
    end

    protected

    def message_edit_done(name = resource_config.label)
      t("admin.flash.successful", :name => name, :action => t("admin.actions.edit.done"))
    end

    def message_new_done(name = resource_config.label)
      t("admin.flash.successful", :name => name, :action => t("admin.actions.new.done"))
    end

    def message_destroy_done(name = resource_config.label)
      t("admin.flash.successful", :name => name, :action => t("admin.actions.delete.done"))
    end

    # for InheritedResources
    def collection
      get_collection_ivar || begin
        form = query_form
        @resource_filter = form.resource_filter
        set_collection_ivar(form.collection)
      end
    end

    def collection_without_paggination
      collection.offset(nil).limit(nil)
    end

    # for InheritedResources
    def resource
      get_resource_ivar || begin
        o = end_of_association_chain.find(params[:id])
        authorize!(action_name.to_sym, o) # CanCan
        set_resource_ivar(o)
      end
    end

    # for InheritedResources
    def build_resource
      get_resource_ivar || begin
        object = end_of_association_chain.send(method_for_build)
        set_resource_ivar(object) # must be first - edit_form (called from resource_params) depends on it
        object.assign_attributes(current_ability.attributes_for(action_name.to_sym, resource_class)) # CanCan TODO - also for nested forms

        object.assign_attributes(*resource_params)
        authorize!(action_name.to_sym, object)
        yield(object) if block_given?
        object
      end
    end

    # for InheritedResources
    def build_resource_params
      # disabled second parameter for Rails 4
      [super.first]
    end

    # for InheritedResources
    def permitted_params
      _params = params[resource_request_name] || params[resource_instance_name]
      return params if _params.blank?
      { resource_instance_name => edit_form.permit_params(_params) }
    end

    def resource_config
      @resource_config ||= Lepidlo::Utils.model_config(resource_class)
    end

    def resource_filter
      @resource_filter || begin
        collection
        @resource_filter
      end
    end

    def collection_includes
      resource_config.fields.select do |f|
        f.type.in?([:belongs_to_association, :has_one_association]) && !f.polymorphic?
      end.map {|f| f.association[:name] }
    end

    def filterql_options
      nil
    end

    def return_to_path
      params[:return_to] if
        params[:return_to].presence and
        params[:return_to] =~ %r{\A\/[a-z]}i and
        params[:return_to] != request.fullpath
    end

    # for InheritedResources
    def smart_resource_url
      return_to_path || super
    end

    # for InheritedResources
    def smart_collection_url
      return_to_path || super
    end

    def collection_action?
      params[:id].nil?
    end

    def chain
      collection_action? ? association_chain + [build_resource] : association_chain + [resource]
    end

    def chain_with_class
      association_chain + [resource_class]
    end

    def title_params
      @title_params || begin
        case action_name.to_sym
        when :index
          resource_class
        when :create, :new
          [[resource, "Nový"]]
        when :edit, :update
          [[resource, "Úprava"]]
        when :show
          resource
        when :export
          [[resource_class, "Export"]]
        else
          collection_action? ? resource_class : resource
        end
      end
    end

    #retruns paramters used by filter and paginator (for generation of link on the same page)
    def query_params
      query_form.params
    end

    def send_export_data(options = {}, &block)
      method = :each

      if params[:send_data]
        set_file_headers filename: "#{resource_class.model_name.plural}_#{DateTime.now.strftime("%Y-%m-%d_%Hh%Mm%S")}.#{request.format.to_sym}"
        method = :find_each if params[:send_data] == 'all' and request.post?
      end

      self.response_body = Enumerator.new do |y|
        y << options[:header] if options[:header]
        i = 0
        collection.send(method) do |object|
          y << yield(object, i)
          i += 1
        end
        y << options[:footer] if options[:footer]
      end
    end

    def set_file_headers(options)
      type_provided = options.has_key?(:type)

      options = options.reverse_merge({ :type => 'application/octet-stream', :disposition => 'attachment' })

      [:type, :disposition].each do |arg|
        raise ArgumentError, ":#{arg} option required" if options[arg].nil?
      end

      disposition = options[:disposition].to_s
      disposition += %(; filename="#{options[:filename]}") if options[:filename]

      content_type = options[:type]

      if content_type.is_a?(Symbol)
        extension = Mime[content_type]
        raise ArgumentError, "Unknown MIME type #{options[:type]}" unless extension
        self.content_type = extension
      else
        if !type_provided && options[:filename]
          # If type wasn't provided, try guessing from file extension.
          content_type = Mime::Type.lookup_by_extension(File.extname(options[:filename]).downcase.tr('.','')) || content_type
        end
        self.content_type = content_type
      end

      headers.merge!(
        'Content-Disposition'       => disposition,
        'Content-Transfer-Encoding' => 'binary'
      )

      response.sending_file = true

      # Fix a problem with IE 6.0 on opening downloaded files:
      # If Cache-Control: no-cache is set (which Rails does by default),
      # IE removes the file it just downloaded from its cache immediately
      # after it displays the "open/save" dialog, which means that if you
      # hit "open" the file isn't there anymore when the application that
      # is called for handling the download is run, so let's workaround that
      response.cache_control[:public] ||= false
    end

    # Forms

    def list_form
      list_form!
    end

    def list_form!(&block)
      @list_form ||= begin
        form = list_form_for(query_form)
        form.configure(&block) if block
        form
      end
    end

    def show_form
      show_form!
    end

    def show_form!(&block)
      @show_form ||= begin
        form = show_form_for(chain)
        form.configure(&block) if block
        form
      end
    end

    def query_form
      query_form!
    end

    def query_form!(&block)
      @query_form ||= begin
        authorize!(action_name.to_sym, resource_class) # CanCan
        form = query_form_for(
          chain_with_class,
          end_of_association_chain.accessible_by(current_ability, action_name.to_sym),
          collection_includes: collection_includes,
          filterql_options: filterql_options
        )
        form.configure(&block) if block
        form
      end
    end

    def edit_form
      edit_form!
    end

    def edit_form!(&block)
      @edit_form ||= begin
        form = edit_form_for(chain)
        form.configure(&block) if block
        form
      end
    end

    def export_form
      export_form!
    end

    def export_form!(&block)
      @export_form ||= begin
        authorize!(:export, resource_class)
        form = export_form_for(query_form)
        form.configure(&block) if block
        form
      end
    end

    def form_factory_rails_admin(section, form_class, *args)
      Lepidlo::Forms::Factories::RailsAdmin.new(section, view_context, form_class).new_form(*args)
    end

    class << self
      def default_query(&block)
        before_filter :only => [:index] do |controller|
          redirect_to polymorphic_path([:query, association_chain, resource_class].flatten, controller.instance_eval(&block))
        end
      end
    end

  end
end
