class Basepack.QueryForm

  constructor: ($container, $menu) ->
    @$container = $container
    @$filters = @$container.find(".filters")
    @$menu = $menu
    @options =
      regional:
        datePicker:
          dateFormat: "mm/dd/yy"
      predicates: { }
      enum_options: { }

    that = @

    @$menu.on "click", "a[data-field-label]", (e) ->
      e.preventDefault()
      that.append $(@).data("field-label"),
                  $(@).data("field-name"),
                  $(@).data("field-type"),
                  $(@).data("field-value"),
                  $(@).data("field-operator"),
                  $(@).data("field-template"),
                  $.now().toString().slice(6, 11)

    @$container.on "click", ".delete", (e) ->
      e.preventDefault()
      form = $(@).parents("form")
      $(@).parents(".filter").remove()
      not that.$filters.children().length and that.$container.hide("fast")

    @$container.on "change", ".predicate", (e) ->
      that.setup_additional_control $(@)

  setup: (data) ->
    @options = data.options
    for field, i in data.initial
      @append field.label, field.name, field.type, field.value, field.predicate, field.template, i

  setup_additional_control: ($predicate_select) ->
    selected_option = $predicate_select.find("option:selected")
    if $(selected_option).data("type") is "boolean"
      $predicate_select.siblings(".additional-fieldset").prop("disabled", true).hide()
      $predicate_select.siblings(".textarea-value").prop("disabled", true).hide()
      $predicate_select.siblings(".boolean-value").prop "disabled", false
    else
      $predicate_select.siblings(".boolean-value").prop "disabled", true
      if $predicate_select.val() == "one_of"
        $predicate_select.siblings(".textarea-value").prop("disabled", false).show()
        $predicate_select.siblings(".additional-fieldset").prop("disabled", true).hide()
      else
        $predicate_select.siblings(".textarea-value").prop("disabled", true).hide()
        $predicate_select.siblings(".additional-fieldset").prop("disabled", false).show()

  select_option: (name, selected, options, klass) ->
    html = "<select class=\"input-medium #{klass || "additional-fieldset"}\" name=\"" + name + "\">"
    $.each options, (i, o) ->
      html += "<option value=\"" + o[0] + "\"" + ((if o[0] is selected then " selected=\"selected\"" else "")) + ">" + o[1] + "</option>"

    html + "</select>"

  select_predicate: (name, value, options, klass) ->
    JST["basepack/forms/query/predicate"]
      name: name
      value: value
      options: options
      klass: klass
      predicates: @options.predicates
      selected: value or "cont"

  append: (field_label, field_name, field_type, field_value, field_predicate, field_template, index) ->
    condition_name = "f[c][" + index + "][a][0][name]"
    value_name = "f[c][" + index + "][v][0][value]"
    operator_name = "f[c][" + index + "][p]"

    if field_template
      console.log(field_template)
      control = _.template(field_template)
        label: field_label,
        type: field_type,
        value: field_value || {},
        predicate: field_predicate,
        index: index,
        name: value_name,
        field_name: field_name,
        condition_name: condition_name,
        operator_name: operator_name,
        select_option: @.select_option
    else
      switch field_type
        when "boolean"
          control = @select_predicate(operator_name, field_predicate or "true", ["true", "false", "null", "not_null"])
        when "date", "datetime", "timestamp"
          control = @select_predicate(operator_name, field_predicate or "eq", ["eq", "not_eq", "lt", "lteq", "gt", "gteq", "present", "blank", "null", "not_null"])
          additional_control = JST["basepack/forms/query/date"]
            name: value_name,
            value: field_value,
            #options: { showTime: false, datepicker: _.defaults({value: field_value}, @options.regional.datePicker) }
        when "enum"
          #var multiple_values = ((field_value instanceof Array) ? true : false)
          control = @select_predicate(operator_name, field_predicate or "eq", ["eq", "not_eq", "null", "not_null"])
          additional_control = @select_option(value_name, field_value, @options.enum_options[field_name] or [])
        when "string", "text", "belongs_to_association"
          control = @select_predicate(operator_name, field_predicate or "cont", ["eq", "not_eq", "matches", "does_not_match", "cont", "not_cont", "start", "not_start", "end", "not_end", "present", "blank", "one_of", "null", "not_null"])
          additional_control = "<input class=\"additional-fieldset input-medium\" type=\"text\" name=\"" + value_name + "\" value=\"" + field_value + "\" /> "
        when "integer", "decimal", "float"
          control = @select_predicate(operator_name, field_predicate or "eq", ["eq", "not_eq", "lt", "lteq", "gt", "gteq", "one_of", "null", "not_null"])
          additional_control = "<input class=\"additional-fieldset default input-medium\" type=\"text\" name=\"" + value_name + "\" value=\"" + field_value + "\" /> "
        when "ql"
          name_control = " "
          control = "<textarea name=\"" + field_name + "\" class=\"input-xlarge\" rows=\"4\" cols=\"50\">" + field_value + "</textarea>"
        else
          control = "<input type=\"hidden\" name=\"" + operator_name + "\" value=\"eq\"/>"
          additional_control = "<input type=\"text\" class=\"input-medium\" name=\"" + value_name + "\" value=\"" + field_value + "\"/> "

    content = JST["basepack/forms/query/filter"]
      index: index,
      name_control: name_control,
      condition_name: condition_name,
      field_name: field_name,
      field_label: field_label
      control: control,
      additional_control: additional_control,
      value_name: value_name
      field_value: field_value

    @$filters.append content
    @$container.show "fast"
    @$filters.find(".filter-#{index} .date").datepicker @options.regional.datePicker
    @.setup_additional_control $(el) for el in @$filters.find(".predicate[name=\"#{operator_name}\"]")
    form = new Basepack.Form(@$filters.find(".filter-#{index}"))
    form.bind()

