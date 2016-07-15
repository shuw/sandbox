window.g_photos = {}
window.g_year_sections = []
window.$root = null

# TODO
# - Typeahead suggestions in search
# - Show larger photo in popover
# - Chronological organization of photos

window.got_data =  (data) ->
  $ ->
    if data.error
      $('#error').text(data.error)

    document.title = data.title

    window.$root = $('#root')
    if data.message
      $('#message')
        .removeClass('hidden')
        .text(data.message)
    else
      $('#loading').hide()

    if !data.index && data.index.length == 0
      return

    $('#root').removeClass('hidden')
    $('#searchContainer').removeClass('hidden')

    createPhotos(data.index)
    $('#search').on('keyup', _.debounce(queryEntered, 100))
    draw()
    $(window).scrollTop(0)


class Photo
  constructor: (@photo) ->
    @tags = []
    for tag, score of @photo.tags
      tag = tag.replace(/[.,\/#!$%\^&\*;:{}=\-_`~()]/g,"")
      for word in _.str.words(tag)
        @tags.push(word.toLowerCase())

    @el = $('<a />')
      .addClass('photo_container')
      .attr('data-id', @photo.id)
      .attr('href', "https://www.facebook.com/#{@photo.id}")
      .attr('target', '_blank')

    @img = $('<img />')
      .addClass('photo')
      .attr('title', _(photo.tags).keys().join(', '))
      .appendTo(@el)

    @setExpanded(false)

  setExpanded: (toggle) ->
    if toggle
      @img
        .removeClass('small')
        .addClass('large')
        .attr('src', @photo.src.large)
    else
      @img
        .addClass('small')
        .removeClass('large')
        .attr('src', @photo.src.small)

  setVisible: (toggle) ->
    if toggle
      @el.show()
    else
      @el.hide()
      
class YearSection

  constructor: (@year) ->
    @photos = []

    @el = $('<div />')
      .addClass('year')
      .appendTo($root)

    $('<h2 />')
      .text(year)
      .appendTo(@el)

    @collage = $('<div />')
      .addClass('collage')
      .appendTo(@el)

  addPhoto: (photo) ->
    @photos.push(photo)
    photo.el.appendTo(@collage)

  applyQuery: (query) ->
    show_section = false
    for photo in @photos
      show = false
      if !query
        show = true
      else
        for tag in photo.tags
          if tag.startsWith(query)
            show = true
            break

      if show
        show_section = true
      photo.setVisible(show)

    if show_section
      @el.show()
    else
      @el.hide()


queryEntered = (index) ->
  query = $('#search').val().toLowerCase()

  for section in g_year_sections
    section.applyQuery(query)

createPhotos = (index) ->
  index = _(index).values()
  index.sort((a, b) -> b.timestamp - a.timestamp)
  
  tag_counts = {}
  photos = {}
  prev_year = null
  for photo in index
    if photo.privacy == 10
      continue

    year = moment.unix(photo.timestamp).year()
    if year != prev_year
      year_section = new YearSection(year)
      g_year_sections.push(year_section)
      prev_year = year

    photo_obj = g_photos[photo.id] = new Photo(photo)
    year_section.addPhoto(photo_obj)
    for tag in photo_obj.tags
      if !tag_counts[tag]
        tag_counts[tag] = 0
      tag_counts[tag] += 1
      

  tags = _(_(tag_counts).keys()).sortBy((tag) -> -1 * tag_counts[tag])
  tag_source = new Bloodhound(
    datumTokenizer: Bloodhound.tokenizers.whitespace,
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    local: tags,
  )

  $('#search').typeahead(
    {
      hint: true,
      highlight: true,
      minLength: 1,
    },
    {
      name: 'tags',
      source: tag_source,
    }
  )

  $('.photo_container').popover({
    content: ->
      photo = g_photos[$(this).attr('data-id')].photo
      $el = $('<div />')
      $('<img />')
        .addClass('photo')
        .addClass('large')
        .attr('src', photo.src.large)
        .appendTo($el)

      $('<div />')
        .addClass('tags')
        .text(_(photo.tags).keys().join(', '))
        .appendTo($el)
      return $el

    html: true,
    trigger: 'hover',
  })

  return photos

createYearContainer = (year) ->
  $section = $('<div />')
    .addClass('year')
    .appendTo($root)

  $('<h2 />')
    .text(year)
    .appendTo($section)

  return $('<div />')
    .addClass('collage')
    .appendTo($section)


draw = ->
  $root = $('#root')

