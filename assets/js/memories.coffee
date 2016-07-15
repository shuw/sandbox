window.g_photos = {}
window.$root = null

# TODO
# - Typeahead suggestions in search
# - Show larger photo in popover
# - Chronological organization of photos

window.got_data =  (data) ->
  $ ->
    if data.error
      $('#error').text(data.error)

    $('#loading').hide()
    $('#stuff').removeClass('hidden')
    document.title = data.title

    window.$root = $('#root')
    window.g_photos  = create_photos(data.index)
    $('#search').on('keyup', _.debounce(queryEntered, 500))
    draw()

class Photo
  constructor: (@photo) ->
    @tags = []
    for tag, score of @photo.tags
      for word in _.str.words(tag)
        @tags.push(word.toLowerCase())

    @el = $('<img />')
      .addClass('photo')
      .attr('title', _(photo.tags).keys().join(', '))
      .appendTo($root)

    # @el.on('mouseover', => @setExpanded(true))
    # @el.on('mouseout', => @setExpanded(false))
    @setExpanded(false)

  setExpanded: (toggle) ->
    if toggle
      @el
        .removeClass('small')
        .addClass('large')
        .attr('src', @photo.src.large)
    else
      @el
        .addClass('small')
        .removeClass('large')
        .attr('src', @photo.src.small)

  setVisible: (toggle) ->
    if toggle
      @el.show()
    else
      @el.hide()
      

queryEntered = (index) ->
  query = $('#search').val().toLowerCase()

  for id, photo of g_photos
    show = false
    if !query
      show = true
    else
      for tag in photo.tags
        if tag.startsWith(query)
          show = true
          break

    photo.setVisible(show)

create_photos = (index) ->
  index = _(index).values()
  index.sort((a, b) -> b.timestamp - a.timestamp)

  for photo in index
    g_photos[photo.id] = new Photo(photo)

draw = ->
  $root = $('#root')

