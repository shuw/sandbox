window.g_photos = {}
window.$root = null

window.got_data =  (data) ->
  $ ->
    if data.error
      $('#error').text(data.error)

    $('#loading').hide()
    document.title = data.title

    window.$root = $('#root')
    window.g_photos  = create_photos(data.index)
    draw()

class Photo
  constructor: (@photo) ->
    @el = $('<img />')
      .attr('src', @photo.src.small)
      .appendTo($root)

  hide: ->
    @el.hide()
      

create_photos = (index) ->
  for id, photo of index
    g_photos[id] = new Photo(photo)

draw = ->
  $root = $('#root')

  for id, photo of g_photos
    photo.hide()
  for id, photo of g_photos
    photo.show()
