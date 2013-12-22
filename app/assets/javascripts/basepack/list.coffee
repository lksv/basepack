# copied from
# https://github.com/phillipp/jquery-ujs/blob/master/src/rails.js#L185-L209
# TODO: change after pull request is accepted
handleMethodParams = (link) ->
  href = link.attr('href')
  method = link.data('bulk-action-method')
  target = link.attr('target')
  params = link.data('params')
  csrf_token = $('meta[name=csrf-token]').attr('content')
  csrf_param = $('meta[name=csrf-param]').attr('content')
  form = $('<form method="post" action="' + href + '"></form>')
  metadata_input = '<input name="_method" value="' + method + '" type="hidden" />'

  if csrf_param isnt 'undefined' && csrf_token isnt 'undefined'
    metadata_input += '<input name="' + csrf_param + '" value="' + csrf_token + '" type="hidden" />'

  if(params)
    for key of params
      metadata_input += '<input name="' + key + '" value="' + params[key] + '" type="hidden" />'

  if (target) 
    form.attr('target', target)

  form.hide().append(metadata_input).appendTo('body')
  form.submit()

$(document).on 'click', '[data-bulk-action-method]', (event) ->
  event.preventDefault()

  # if element with 'data-bulk-actions-params' is set, get params from it
  # instead search for checkboxes named 'bulk_ids[]' 
  if $("[data-bulk-actions-params]").length == 0
    ids = $("input[name^='bulk_ids[]']:checked").map(->
      return $(@).val()
    ).get()
    $(@).data('params', ids: ids)
  else
    params = $("[data-bulk-actions-params]").data('bulk-actions-params')
    $(@).data('params', params)

  handleMethodParams($(@))

  return true

