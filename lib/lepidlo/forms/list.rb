module Lepidlo
  module Forms
    class List < Forms::Base
      attr_reader :query_form

      def initialize(factory, chain, options = {})
        super(factory, chain, options)
        @query_form = options[:query_form]
      end

      def view=(view)
        super
        @query_form.view = view if @query_form
      end

      def default_partial
        'forms/list'
      end

      def collection
        @query_form ? @query_form.collection : []
      end

      def collection_each(&block)
        collection.each_with_index do |res, i|
          with_resource(res, res, i, &block)
        end
      end

      render :sort_link do |field|
        view.form_sort_link(@query_form.resource_filter, field, @query_form.params)
      end

      render :row do |&block|
        view.content_tag(:tr, &block)
      end

      render :action do |name, url, icon=nil, html_options={}|
        view.link_to (icon ? "<i class='#{icon}'></i> ".html_safe + name : name), url, html_options.reverse_merge(class: "btn btn-mini")
      end

      render :actions do
        result = ''.html_safe
        if view.can? :show, resource
          result << render_action("Zobrazit", [association_chain, resource].flatten, "icon-eye-open")
        end
        if view.can? :edit, resource
          result << render_action("Upravit", [:edit, association_chain, resource].flatten, "icon-pencil",
                                  class: 'btn btn-info btn-mini')
        end
        if view.can? :destroy, resource
          result << render_action("Smazat", [association_chain, resource].flatten, "icon-trash",
                                  class: 'btn btn-mini btn-danger',
                                  method: :delete,
                                  data: { confirm: "Jste si jistí?" })
        end
        result
      end
    end
  end
end
