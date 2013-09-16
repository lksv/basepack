$.fn.findExtended = (selector) ->
  if _.str.startsWith(selector, "parent=")
    @.parents(selector.substring("parent=".length))
  else if _.str.startsWith(selector, "field=")
    @.parents(".form-inputs:first").find("*[name$='[" + selector.substring("field=".length) + "]']")
  else
    $(selector)

$(document).on 'nested:fieldAdded', 'form', (content) ->
  form = new Lepidlo.Form(content.field)
  form.bind()

$(document).on 'click.data-api', '[data-toggle="checkboxes"]', ->
  $($(@).data('target')).prop "checked", $(@).is(":checked")

$(document).on 'click.data-api', '[data-toggleclass]', (e) ->
  $(@).toggleClass($(@).data("toggleclass"));

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
  form = new Lepidlo.Form()
  form.bind()

window.Lepidlo = {}

class Lepidlo.Form
  constructor: ($container) ->
    @$container = $container || $('form')
    @plugins = []

    if @$container.length # don't waste time otherwise
      plugins = _.sortBy Lepidlo.Form.Plugins, (p) ->
        -p.priority
      for klass in plugins
        @plugins.push(new klass(@))

  find: (selector) ->
    @$container.find(selector)

  bind: ->
    for object in @plugins
      object.bind()

Lepidlo.Form.Plugins = {}

class Lepidlo.Form.Plugin
  @priority: 100
  constructor: (form) ->
    @form = form
  bind: ->

class Lepidlo.Form.Plugins.ColorPicker extends Lepidlo.Form.Plugin
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

class Lepidlo.Form.Plugins.DateTime extends Lepidlo.Form.Plugin
  bind: ->
    @form.find('[data-datetimepicker]').each ->
      $(@).datetimepicker $(@).data('options')

class Lepidlo.Form.Plugins.FileUpload extends Lepidlo.Form.Plugin
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

class Lepidlo.Form.Plugins.FilteringSelect extends Lepidlo.Form.Plugin
  bind: ->
    @form.find('[data-filteringselect]').each ->
      Lepidlo.Form.Plugins.FilteringSelect.select2 $(@), $(@).data('options')

  @select2: ($el, options) ->
    options = _.extend(
      {
        remote_source_params: {},
        init: {},
        minimum_input_length: 0
      },
      options
    )
    $el.select2
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
      ajax:
        url: options.remote_source
        dataType: 'json'
        data: (term, page) ->
          params = { query: term, page: page, per: 20 } # TODO - per into Settings
          $.extend(params, options.remote_source_params)
          params
        results: (data, page) ->
          { more: data.length == (options.remote_source_params.per || 20), results: data }
      initSelection: (element, callback) ->
        if options.multiple
          Lepidlo.Form.Plugins.FilteringSelect.select2InitSelectionMultiple(element, callback, options, $el)
        else
          Lepidlo.Form.Plugins.FilteringSelect.select2InitSelection(element, callback, options, $el)

  @select2InitSelection: (element, callback, options, $el) ->
    id = element.val()
    if options.init[id]
      callback(
        id:   id
        text: options.init[id]
      )
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
     else
       $.ajax(options.remote_source,
         data: $.extend({ f: { id_eq: ids_for_ajax }}, options.remote_source_params)
         dataType: "json"
       ).done (d) ->
         callback(data.concat(d))

class Lepidlo.Form.Plugins.FilteringMultiSelect extends Lepidlo.Form.Plugin
  bind: ->
    @form.find('[data-filteringmultiselect]').each ->
      $(@).select2
        placeholder: $(@).data('placeholder')

class Lepidlo.Form.Plugins.WysiwigHtml5 extends Lepidlo.Form.Plugin
  bind: ->
    @form.find('[data-richtext=bootstrap-wysihtml5]').not('.bootstrap-wysihtml5ed').each ->
      $(@).addClass('bootstrap-wysihtml5ed')
      $(@).closest('.controls').addClass('well')
      $(@).wysihtml5() #TODO implement settings of config_options

class Lepidlo.Form.Plugins.RemoveOnCollapse extends Lepidlo.Form.Plugin
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

class Lepidlo.Form.Plugins.DependantFilteringSelect extends Lepidlo.Form.Plugin
  bind: ->
    @form.find('[data-dependant-filteringselect]').each ->
      that = $(@)
      dependsOn = that.findExtended(that.data('dependantFilteringselect'))
      dependsOn.on 'change', (e) ->
        options = _.clone(that.data('options'))
        if e.val != "" and e.val?
          options.remote_source_params = _.clone(options.remote_source_params)
          options.remote_source_params[that.data('dependantParam')] = e.val
        that.val(null) # to prevent "initSelection" query when select2 is redefined
        Lepidlo.Form.Plugins.FilteringSelect.select2 that, options
        that.val(that.data('dependantDefaultvalue')).trigger('change').trigger('remoteSourceParamsChange', options)

class Lepidlo.Form.Plugins.HiddeningFilteringSelect extends Lepidlo.Form.Plugin
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
 * Dynamically show/hide fields based on other field value.

 * takes all elements with data-dynamic-fields and use this data attribute as an configuration:
   @param{data-dynamic-fields} array of actions. Each action is a hash with keys: 
   condition - condition which should be met (Stirng: field has to equal, Array: field has to match one of item of array)
   fields_actin - hash. Keys are other fields on which are taken action.

 * Exmaple:
   [{"condition":["aaa","hide"],"fields_actin":{"www":{"visible":false}}},{"condition":"xxx","fields_actin":{"www":{"visible":true}}}]
 ###

class Lepidlo.Form.Plugins.DynamicFields extends Lepidlo.Form.Plugin
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
          fields_actin = options.fields_actin
          if plugin.value_checker(current_value, value_condition)
            $.each fields_actin, (field_name, field_options) ->
              field = that.findExtended("field=" + field_name)
              if field and field_options.visible == true or field_options.visible == false
                fieldDom = $(field).parents(".control-group")
                if field_options.visible 
                  fieldDom.show() #slideDown()
                else
                  fieldDom.hide() #slideUp()
      $(@).trigger('change').trigger('change')

class Lepidlo.Form.Plugins.Select2 extends Lepidlo.Form.Plugin
  bind: ->
    @form.find('[data-select]').each ->
      $(@).select2($(@).data('select'))

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

