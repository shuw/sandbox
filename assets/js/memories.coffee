window.g_photos = {}
window.g_year_sections = []
window.$root = null

# TODO
# - Group results by search match term and show the shortest matches first
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

    if !data.index || data.index.length == 0
      if data.estimated_time_s
        window.setTimeout(
          -> window.location.reload(),
          data.estimated_time_s * 1000,
        )
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
      .attr('title', _(photo.tags).keys().join(', '))
      .appendTo(@el)

  setSize: (size) ->
    @img
      .removeClass()
      .addClass('photo')
      .addClass(size)
    if size == 'large'
      @img.attr('src', @photo.src.small)
    else
      @img.attr('src', @photo.src.small)

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

  applyQuery: (terms) ->
    matches = []
    show_section = false
    for photo in @photos
      show = true
      for term in terms
        term_match = false
        for tag in photo.tags
          if tag.startsWith(term)
            term_match = true
            break

        if !term_match
          show = false
          break

      if show
        matches.push(photo)
        show_section = true
      photo.setVisible(show)

    if show_section
      @el.show()
    else
      @el.hide()

    return matches


queryEntered = (index) ->
  query = _.str.words($('#search').val().toLowerCase())

  matches = []
  for section in g_year_sections
    matches = matches.concat(section.applyQuery(query))

  if matches.length < 20
    size = 'large'
  else if matches.length < 100
    size = 'medium'
  else
    size = 'small'

  for match in matches
    match.setSize(size)


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
        .addClass('preview')
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

  queryEntered()
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

