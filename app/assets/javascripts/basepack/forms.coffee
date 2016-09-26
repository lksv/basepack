$.fn.findExtended = (selector) ->
  if _.str.startsWith(selector, "parent=")
    @.parents(selector.substring("parent=".length))
  else if _.str.startsWith(selector, "field=")
    @.parents(".form-inputs:first").find("*[name$='[" + selector.substring("field=".length) + "]']")
  else
    $(selector)

$(document).on 'nested:fieldAdded', 'form', (content) ->
  form = new Basepack.Form(content.field)
  form.bind()

$(document).on 'click.data-api', '[data-toggle="checkboxes"]', ->
  $($(@).data('target')).prop "checked", $(@).is(":checked")

$(document).on 'click.data-api', '[data-toggleclass]', (e) ->
  $(@).toggleClass($(@).data("toggleclass"))

$(document).on 'click.data-api', '[data-toggle="ajax-modal"]', (e) ->
  # ajax modals
  $("body").modalmanager "loading" # create the backdrop and wait for next modal to be triggered
  $modal = $("<div class='ajax-modal modal hide fade' tabindex='-1' data-focus-on='input:first'>")
  options = $(@).data()
  $modal.load $(@).attr("href"), $(@).data("params"), ->
    $modal.modal(options)
  e.preventDefault()

$(document).on 'click.data-api', '[data-remote-form]', (e) ->
  $form = $(@).findExtended($(@).data("remoteForm"))
  $target = $(@).findExtended($(@).data("remoteTarget"))
  $form.on 'ajax:success.remoteForm', (event, data, status, xhr) ->
    $target.replaceWith(data)
    $form.off '.remoteForm'
  $form.on 'ajax:error.remoteForm', (event, xhr, status, error) ->
    # TODO - errors
    $form.off '.remoteForm'

  $.rails.handleRemote($form)
  e.preventDefault()

$(document).on 'page:load', ->
  # fixes for DataPicker and TimePicker under Turbolinks
  jQuery.datepicker.dpDiv.appendTo(jQuery('body'))
  jQuery.timepicker.tpDiv.appendTo(jQuery('body'))

$ ->
  # Tooltips
  $('.form-show,.form-export').tooltip({ selector: "*[data-toggle=tooltip]" })
  form = new Basepack.Form()
  form.bind()

window.Basepack ||= {}

class Basepack.Form
  constructor: ($container) ->
    @$container = $container || $('form')
    @plugins = []

    if @$container.length # don't waste time otherwise
      # instanciate and store plugins in order of their priorities
      plugins = _.sortBy Basepack.Form.Plugins, (p) ->
        -p.priority
      for klass in plugins
        @plugins.push(new klass(@))

  find: (selector) ->
    @$container.find(selector)

  bind: ->
    for object in @plugins
      object.bind()

Basepack.Form.Plugins = {}

class Basepack.Form.Plugin
  # default priority
  @priority: 100
  constructor: (form) ->
    @form = form
  bind: ->

class Basepack.Form.Plugins.ColorPicker extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-color]').each ->
      that = @
      $(@).ColorPicker
        color: $(that).val()
        onShow: (el) ->
          $(el).fadeIn(500)
          false
        onHide: (el) ->
          $(el).fadeOut(500)
          false
        onChange: (hsb, hex, rgb) ->
          $(that).val(hex)
          $(that).css('backgroundColor', '#' + hex)

class Basepack.Form.Plugins.DateTime extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-datetimepicker]').each ->
      $(@).datetimepicker $(@).data('options')

class Basepack.Form.Plugins.FileUpload extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-fileupload]').each ->
      input = @
      $(@).on 'click', ".delete input[type='checkbox']", ->
        $(input).children('.toggle').toggle('slow') # TODO - this is what?

    # file upload preview
    @form.find('[data-fileupload]').change ->
      input = @
      image_container = $("#" + input.id).parent().children(".preview")
      unless image_container.length
        image_container = $("#" + input.id).parent().prepend($('<img />').addClass('preview')).find('img.preview')
        image_container.parent().find('img:not(.preview)').hide()
      ext = $("#" + input.id).val().split('.').pop().toLowerCase()
      if input.files and input.files[0] and $.inArray(ext, ['gif','png','jpg','jpeg','bmp']) != -1
        reader = new FileReader()
        reader.onload = (e) ->
          image_container.attr "src", e.target.result
        reader.readAsDataURL input.files[0]
        image_container.show()
      else
        image_container.hide()

class Basepack.Form.Plugins.FilteringSelect extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-filteringselect]').each ->
      Basepack.Form.Plugins.FilteringSelect.select2 $(@), $(@).data('options')

  @select2: ($el, options) ->
    options = _.extend(
      {
        remote_source_params: {},
        init: {},
        minimum_input_length: 0
      },
      options
    )
    select_options =
      createSearchChoice: (term, data) ->
        if options.create_search_choice
          {id:term, text:term}
        else
          null
      placeholder: options.placeholder
      minimumInputLength: options.minimum_input_length
      allowClear: !options.required
      multiple: options.multiple
      escapeMarkup: (m) ->
        m
      initSelection: (element, callback) ->
        if options.multiple
          Basepack.Form.Plugins.FilteringSelect.select2InitSelectionMultiple(element, callback, options, $el)
        else
          Basepack.Form.Plugins.FilteringSelect.select2InitSelection(element, callback, options, $el)

    if options.precached_options
      select_options.data = options.precached_options
    else
      select_options.ajax =
        url: options.remote_source
        dataType: 'json'
        data: (term, page) ->
          params = { query: term, page: page, per: 200 } # TODO - move 'per' into Settings
          $.extend(params, options.remote_source_params)
          params
        results: (data, page) ->
          { more: data.length == (options.remote_source_params.per || 200), results: data }

    $el.select2 select_options

    # initSelection is not called when no initial value is provided
    # that means 'filtering-select-ready' is not triggered therefore we must trigger it now
    $el.trigger('filtering-select-ready') unless $el.val()

  @select2InitSelection: (element, callback, options, $el) ->
    id = element.val()
    if options.init[id]
      callback(
        id:   id
        text: options.init[id]
      )
      $el.trigger('filtering-select-ready')
    else
      $.ajax(options.remote_source,
        data: $.extend({ f: { id_eq: id }}, options.remote_source_params)
        dataType: "json"
      ).done (data) ->
        if _.isEmpty(data)
          $el.select2("val", "", true)
        else
          $.each data, (i, object) ->
            callback(object)
            $el.select2("data", object, true) if id != object.id

        $el.trigger('filtering-select-ready')

  @select2InitSelectionMultiple: (element, callback, options, $el) ->
    data = []
    ids_for_ajax = []
    $.each element.val().split(","), (i, id) ->
      if options.init[id]
        data.push
          id:   id
          text: options.init[id]
      else
        ids_for_ajax.push(id)

     if _.isEmpty(ids_for_ajax)
       callback(data)
       $el.trigger('filtering-select-ready')
     else
       $.ajax(options.remote_source,
         data: $.extend({ f: { id_eq: ids_for_ajax }}, options.remote_source_params)
         dataType: "json"
       ).done (d) ->
         callback(data.concat(d))
         $el.trigger('filtering-select-ready')


class Basepack.Form.Plugins.FilteringMultiSelect extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-filteringmultiselect]').each ->
      $(@).select2
        placeholder: $(@).data('placeholder')

class Basepack.Form.Plugins.WysiwigHtml5 extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-richtext=bootstrap-wysihtml5]').not('.bootstrap-wysihtml5ed').each ->
      $(@).addClass('bootstrap-wysihtml5ed')
      $(@).closest('.controls').addClass('well')
      $(@).wysihtml5() #TODO implement settings of config_options

class Basepack.Form.Plugins.RemoveOnCollapse extends Basepack.Form.Plugin
  @priority: -1000
  bind: ->
    @form.find('[data-removeoncollapse]').each ->
      $this = $(@)
      $target = $($this.attr("href"))
      parent = $target.parent()

      if $target.hasClass('in')
        $this.addClass('toggle-chevron')
      else
        $target.appendTo($('body'))

      $target.on "hide", (e) ->
        $this.removeClass('toggle-chevron')
      $target.on "hidden", (e) ->
        $target.appendTo($('body'))
      $target.on "show", (e) ->
        $this.addClass('toggle-chevron')
        $target.appendTo(parent)

class Basepack.Form.Plugins.DependantFilteringSelect extends Basepack.Form.Plugin
  # should be more than filteringSelect because this must happen before trigger
  @priority: 200

  bind: ->
    @form.find('[data-dependant-filteringselect]').each ->
      that = $(@)
      dependsOn = that.findExtended(that.data('dependantFilteringselect'))

      dependsOn.on 'filtering-select-ready', () ->
        dependsOn.on 'change', (e) ->
          options = _.clone(that.data('options'))
          if e.val != "" and e.val?
            options.remote_source_params = _.clone(options.remote_source_params)
            options.remote_source_params[that.data('dependantParam')] = e.val
          that.val(null) # to prevent "initSelection" query when select2 is redefined
          Basepack.Form.Plugins.FilteringSelect.select2 that, options
          that.val(that.data('dependantDefaultvalue')).trigger('change').trigger('remoteSourceParamsChange', options)

class Basepack.Form.Plugins.HiddeningFilteringSelect extends Basepack.Form.Plugin
  bind: ->
    plugin = @
    @form.find('[data-hiddening-filteringselect]').each ->
      that = $(@)
      group = that.parents('.control-group:first')
      group.hide()
      plugin.ajax that.data('options'), group

      that.on 'remoteSourceParamsChange', (e, options) ->
        plugin.ajax options, group

  ajax: (options, group) ->
    $.ajax(options.remote_source,
      data: $.extend({}, options.remote_source_params, { per: 1 })
      dataType: "json"
    ).done (data) ->
      if _.isEmpty(data)
        group.hide()
      else
        group.show()

###*
 * @name DynamicRemoteField automatically re-renders field(s) depending on the change of other field

 * @description takes all elements with data-dynamic-remote-field which identifies select on which value change
 this element (with data-dynamic-remote-field attribute) is rerendered with values of remote  call

 NOTE: parameters are brought from html data attributes
 * @param {String} data-dynamic-remote-field identification of the field which changes are watched
 * @param {String} dependant-param additional parameter that is send to remote
 * @param {Object} options contains url adress (remote_sourece key) to which ajax request is made to obtain data (html template)

 * @returns {html} returns html template

 * @example on the field gift_packages following html data attribues are added

  * this is haml
  .accordion{:data=>{
    "dynamic-remote-field"=>"#subscription_order_order_template_id",
    "dependant-param"=>"subscription_order[order_template_id]",
    "options"=>"{\"remote_source\":\"/subscription_orders/gift_packages_partial\"}"}
  }
    %div.content Custom content

  * this is the order_template field definition in meta data
  field :order_template do
    help ''
    param = "f[main_magazine_magazine_group_id_eq]"
    options_source_params do
      { param => bindings[:object].magazine_group.try(:id) || -1,
        'f[offerable]' => true,
        'f[s]' => 'price asc'
      }
    end
    html_attributes do
      {
        data: {
          "dependant-filteringselect" => "#subscription_order_magazine_group_id",
          "dependant-param" => param,
          :placeholder => "Vyberte, prosím"
        }
      }
    end
  end
 ###

class Basepack.Form.Plugins.DynamicRemoteField extends Basepack.Form.Plugin
  bind: ->
    # bind to fields with html attributes
    plugin = @
    @form.find('[data-dynamic-remote-field]').each ->
      that = $(@)
      group = that.parents('.control-group:first')

      # on change make new ajax request
      dependsOn = that.findExtended(that.data('dynamic-remote-field'))
      dependsOn.on 'change', (e) ->
        options = _.clone(that.data('options'))
        if e.val != "" and e.val?
          options.remote_source_params = _.clone(options.remote_source_params) || {}
          options.remote_source_params[that.data('dependantParam')] = e.val
          remoteFieldName = $(this).attr('name')
          options.remote_source_params.remote_field_name = remoteFieldName
          plugin.ajax options, group

  ajax: (options, group) ->
    $.ajax(options.remote_source,
      data: $.extend({}, options.remote_source_params)
      dataType: "html"
    ).done (data) ->
      # reload(rerender) form with new data
      group.html(data)
    .fail ->
      group.html('<div class="alert alert-error">Could not load data from server. We are sorry.</div>')

###*
 * Dynamically show/hide fields based on other field value.

 * takes all elements with data-dynamic-fields and use this data attribute as an configuration:
   @param{data-dynamic-fields} array of actions. Each action is a hash with keys:
   condition - condition which should be met (Stirng: field has to equal, Array: field has to match one of item of array)
   field_actions - hash. Keys are other fields on which are taken action.

 * Exmaple:
   [{"condition":["aaa","hide"],"field_actions":{"www":{"visible":false}}},{"condition":"xxx","field_actions":{"www":{"visible":true}}}]
 ###

class Basepack.Form.Plugins.DynamicFields extends Basepack.Form.Plugin
  value_checker: (field_value, value_condition) ->
    if ((Object.prototype.toString.call(value_condition)) == '[object Array]')
      return (value_condition.indexOf(field_value) != -1)
    else if (field_value == value_condition)
      return true
    else
      return false

  bind: ->
    plugin = @
    @form.find('[data-dynamic-fields]').each ->
      that = $(@)
      dependant = that.data('dynamic-fields')
      $(@).on "change", (e) ->
        current_value = $(this).val()
        if $(this).is('input[type="checkbox"]')
          current_value = $(this).is(':checked')
        for options in dependant
          value_condition = options.condition
          field_actions = options.field_actions
          if !field_actions
            throw new Error("Parameter field_actions must be set!")
          if plugin.value_checker(current_value, value_condition)
            $.each field_actions, (field_name, field_options) ->
              field = that.findExtended("field=" + field_name)
              if field and field_options.visible == true or field_options.visible == false
                fieldDom = $(field).parents(".control-group")
                if field_options.visible
                  fieldDom.show() #slideDown()
                else
                  fieldDom.hide() #slideUp()
      $(@).trigger('change').trigger('change')

class Basepack.Form.Plugins.Select2 extends Basepack.Form.Plugin
  bind: ->
    @form.find('[data-select]').each ->
      $(@).select2($(@).data('select'))


class Basepack.Form.Plugins.Orderable extends Basepack.Form.Plugin
  update_sort_order: ->
    @form.find('.fields').each (idx,fields) ->
      $(fields).find('input[name$="[position]"]').val(idx+1)

  bind: ->
    plugin = @
    @form.find('[data-orderable]').each ->
      $(@).sortable(
        handle: '.nested-form-drag',
        axis: "y",
        stop: =>
          plugin.update_sort_order()
      )

  #$('form [data-enumeration]').each ->
  #  if $(this).is('[multiple]')
  #    $(this).filteringMultiselect $(this).data('options')
  #  else
  #    $(this).filteringSelect $(this).data('options')


    # filtering-multiselect

    #$('form [data-filteringmultiselect]').each ->
    #  $(this).filteringMultiselect $(this).data('options')
    #  if $(this).parents("#modal").length # hide link if we already are inside a dialog (endless issues on nested dialogs with JS)
    #    $(this).parents('.control-group').find('.btn').remove()
    #  else
    #    $(this).parents('.control-group').first().remoteForm()

    # filtering-select

    #$('form [data-filteringselect]').each ->
    #  $(this).filteringSelect $(this).data('options')
    #  if $(this).parents("#modal").length # hide link if we already are inside a dialog (endless issues on nested dialogs with JS)
    #    $(this).parents('.control-group').find('.btn').remove()
    #  else
    #    $(this).parents('.control-group').first().remoteForm()

    # nested-many

    #$('form [data-nestedmany]').each ->
    #  field = $(this).parents('.control-group').first()
    #  nav = field.find('> .controls > .nav')
    #  content = field.find('> .tab-content')
    #  toggler = field.find('> .controls > .btn-group > .toggler')
    #  # add each nested field to a tab-pane and reference it in the nav
    #  content.children('.fields:not(.tab-pane)').addClass('tab-pane').each ->
    #    $(this).attr('id', 'unique-id-' + (new Date().getTime()) + Math.floor(Math.random()*100000)) # some elements are created on the same ms
    #    nav.append('<li><a data-toggle="tab" href="#' + this.id + '">' + $(this).children('.object-infos').data('object-label') + '</a></li>')
    #  # only if no tab is set to active
    #  if nav.find("> li.active").length == 0
    #    # init first tab, toggler and content/tabs visibility
    #    nav.find("> li > a[data-toggle='tab']:first").tab('show')
    #  if nav.children().length == 0
    #    nav.hide()
    #    content.hide()
    #    toggler.addClass('disabled').removeClass('active').children('i').addClass('icon-chevron-right')
    #  else
    #    if toggler.hasClass('active')
    #      nav.show()
    #      content.show()
    #      toggler.children('i').addClass('icon-chevron-down')
    #    else
    #      nav.hide()
    #      content.hide()
    #      toggler.children('i').addClass('icon-chevron-right')

    # nested-one

    #$('form [data-nestedone]').each ->
    #  field = $(this).parents('.control-group').first()
    #  nav = field.find("> .controls > .nav")
    #  content = field.find("> .tab-content")
    #  toggler = field.find('> .controls > .toggler')
    #  content.children(".fields:not(.tab-pane)").addClass('tab-pane active').each ->
    #    nav.append('<li><a data-toggle="tab" href="#' + this.id + '">' + $(this).children('.object-infos').data('object-label') + '</a></li>')
    #  first_tab = nav.find("> li > a[data-toggle='tab']:first")
    #  first_tab.tab('show')
    #  field.find("> .controls > [data-target]:first").html('<i class="icon-white"></i> ' + first_tab.html())
    #  if toggler.hasClass('active')
    #    toggler.children('i').addClass('icon-chevron-down')
    #    content.show()
    #  else
    #    toggler.children('i').addClass('icon-chevron-right')
    #    content.hide()

    # polymorphic-association

    #$('form [data-polymorphic]').each ->
    #  type_select = $(this)
    #  field = type_select.parents('.control-group').first()
    #  object_select = field.find('select').last()
    #  urls = type_select.data('urls')
    #  type_select.on 'change', (e) ->
    #    if $(this).val() is ''
    #      object_select.html('<option value=""></option>')
    #    else
    #      $.ajax
    #        url: urls[type_select.val()]
    #        data:
    #          compact: true
    #          all: true
    #        beforeSend: (xhr) ->
    #          xhr.setRequestHeader("Accept", "application/json")
    #        success: (data, status, xhr) ->
    #          html = '<option></option>'
    #          $(data).each (i, el) ->
    #            html += '<option value="' + el.id + '">' + el.label + '</option>'
    #          object_select.html(html)

    # ckeditor

    #goCkeditors = ->
    #  $('form [data-richtext=ckeditor]').not('.ckeditored').each (index, domEle) ->
    #    try
    #      if instance = window.CKEDITOR.instances[this.id]
    #        instance.destroy(true)
    #    window.CKEDITOR.replace(this, $(this).data('options'))
    #    $(this).addClass('ckeditored')

    #$editors = $('form [data-richtext=ckeditor]').not('.ckeditored')
    #if $editors.length
    #  if not window.CKEDITOR
    #    options = $editors.first().data('options')
    #    window.CKEDITOR_BASEPATH = options['base_location']
    #    $.getScript options['jspath'], (script, textStatus, jqXHR) =>
    #      goCkeditors()
    #  else
    #    goCkeditors()

    ## codemirror

    #goCodeMirrors = (array) =>
    #  array.each (index, domEle) ->
    #    options = $(this).data('options')
    #    textarea = this
    #    $.getScript options['locations']['mode'], (script, textStatus, jqXHR) ->
    #      $('head').append('<link href="' + options['locations']['theme'] + '" rel="stylesheet" media="all" type="text\/css">')
    #      CodeMirror.fromTextArea(textarea,{mode:options['options']['mode'],theme:options['options']['theme']})
    #      $(textarea).addClass('codemirrored')

    #array = $('form [data-richtext=codemirror]').not('.codemirrored')
    #if array.length
    #  @array = array
    #  if not window.CodeMirror
    #    options = $(array[0]).data('options')
    #    $('head').append('<link href="' + options['csspath'] + '" rel="stylesheet" media="all" type="text\/css">')
    #    $.getScript options['jspath'], (script, textStatus, jqXHR) =>
    #      goCodeMirrors(@array)
    #  else
    #    goCodeMirrors(@array)

    ## bootstrap_wysihtml5

    #goBootstrapWysihtml5s = (array, config_options) =>
    #  array.each ->
    #    $(@).addClass('bootstrap-wysihtml5ed')
    #    $(@).closest('.controls').addClass('well')
    #    $(@).wysihtml5(config_options)

    #array = $('form [data-richtext=bootstrap-wysihtml5]').not('.bootstrap-wysihtml5ed')
    #if array.length
    #  @array = array
    #  options = $(array[0]).data('options')
    #  config_options = $.parseJSON(options['config_options'])
    #  if not window.wysihtml5
    #    $('head').append('<link href="' + options['csspath'] + '" rel="stylesheet" media="all" type="text\/css">')
    #    $.getScript options['jspath'], (script, textStatus, jqXHR) =>
    #      goBootstrapWysihtml5s(@array, config_options)
    #  else
    #    goBootstrapWysihtml5s(@array, config_options)

