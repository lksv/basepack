module FormHelper
  def form_setup_simple_form simple_form
    (params[:return_to] ? hidden_field_tag(:return_to, params[:return_to]) : '') +
      simple_form.error_notification.to_s
  end

  def form_display_base_errors resource
    resource = resource.last if resource.is_a? Array
    return '' if resource.errors.empty? or resource.errors[:base].empty?
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div class="alert alert-error alert-block">
      <button type="button" class="close" data-dismiss="alert">&#215;</button>
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def form_hash_to_hidden_fields(hash)
    cleaned_hash = hash.reject { |k, v| v.nil? }
    pairs        = cleaned_hash.to_query.split(Rack::Utils::DEFAULT_SEP)

    tags = pairs.map do |pair|
      key, value = pair.split('=', 2).map { |str| Rack::Utils.unescape(str) }
      hidden_field_tag(key, value)
    end

    tags.join("\n").html_safe
  end

  def form_render(form, &block)
    form.view = self
    block ? capture(form, &block) : form.render
  end

  def form_field_id(form, field)
    field = field.respond_to?(:to_str) ? field : field.method_name
    "#{form.object_name}[#{field}".gsub(/(\])?\[/, "_")
  end

  def form_field_show(field)
    classes = "#{field.type_css_class} #{field.css_class}"
    content_tag(:dt, field.label, class: classes, title: field.label) +
    content_tag(:dd, class: classes) do
      content_tag(:span, "data-toggle" => "tooltip", "data-placement" => "top", "data-delay" => "500",
          title: field.label # field.help.present? ? "#{field.label} (#{field.help})" : field.label
      ) do
        field.pretty_value.presence || "-"
      end
    end
  end

  def form_field_show_association(field)
    try_url = true
    value = Array.wrap(field.value).select(&:present?).map do |associated|
      url = nil
      if try_url and can?(:show, associated)
        begin
          url = url_for(associated)
        rescue
          try_url = false
        end
      end
      if url
        link_to(associated.to_label, url)
      else
        html_escape(associated.to_label)
      end
    end.to_sentence

    value.blank? ? ' - ' : value.html_safe
  end

  def form_sort_link(search, field, url_params = nil, html_options = {})
    raise TypeError, "First argument must be a Ransack::Search!" unless Ransack::Search === search

    columns = Lepidlo::Utils.field_sortable_columns(field)
    return field.label.to_s if columns.blank?

    current = Hash[search.sorts.map {|s| [ s.name, s.dir == 'desc' ] }]

    s = if columns.size == 1
      name, dir = columns.first
      "#{name} #{dir ^ (current[name] == dir) ? 'desc': 'asc'}"
    else
      Hash[columns.map.with_index do |c, i|
        n, d = c
        [ i, { name: n, dir: d ^ (current[n] == d)? 'desc' : 'asc' } ]
      end]
    end

    url_params = url_params ? url_params.dup : {}
    url_params[search.context.search_key] = url_params.fetch(search.context.search_key, {}).merge(s: s)

    current_dir = case current[columns.first[0]]
    when true  then 'desc'
    when false then 'asc'
    else nil
    end

    link_to [html_escape(field.label.to_s), order_indicator_for(current_dir)].compact.join(' ').html_safe,
      url_for(url_params),
      html_options.dup.merge( class: ['sort_link', current_dir, html_options[:class]].compact.join(' ') )
  end

  # Forms a json represenation of available filters
  def query_menu2metadata(form)
    form.visible_groups.map do |group|
      fields = group.visible_fields.select {|f| f.filterable? }
      next unless fields.present?

      fields_metadata = fields.map do |field|
        if field.association?
          unless form.nested_in or form.inverse_of_nested_in?(field) or field.polymorphic? # TODO - polymorphic
            {
              type:   'query-menu-item',
              fields: query_menu2metadata(field.nform),
              label:  field.label,
            }
          end
        else
          {
            nested_label: field.nested_label,
            name:         form.field_nested_name(field),
            type:         "query-menu-#{field.type}",
            field_type:   field.type,
            template:     field.render,
            value:        "",
            label:        field.label
          }
        end
      end.compact
      {
        fields: fields_metadata,
        label: group.label,
        type: 'query-menu-group'
      }
    end.compact
  end

end
