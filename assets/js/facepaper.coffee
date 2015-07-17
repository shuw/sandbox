window.g_sections = {}
window.g_links = []

window.got_data =  (data) ->
  $ -> 
    window.g_sections = data.sections
    if data.error
      $('#error').text(data.error)

    $('#loading').hide()
    document.title = data.title
    $('#title').text(data.title)
    create_sections()

create_sections = ->
  $root = $('#root')

  $section = create_section('Life Events', 'life_events')
  for o in g_sections.life_events
    $section.append create_base_story o

  $section = create_section("Travels", 'travels', false)
  $section.append create_traveled_map g_sections.visited_cities

  $section = create_section("Top Places", 'places')
    .addClass('places')
  for o in g_sections.top_places
    $section.append create_place_story o

  $section = create_section('Top Activities', 'activities')
  for o in g_sections.minutiaes
    $section.append create_minutiae_story o

  $section = create_section('Most Popular Posts', 'popular')
  for o in g_sections.popular.liked_posts
    $section.append create_base_story o

  $section = create_section('Liked by Friends', 'liked')
  for o in g_sections.popular.liked_by_friends
    $section.append create_base_story o

  $section = create_section('New Connections', 'new_connections')
    .addClass('new_connections')
  for o in g_sections.new_friends
    $section.append create_new_friend_story o

  $links = $('#links')
  for o in g_links
    $('<a />')
      .text(o.title)
      .attr('href', '#' + o.name)
      .appendTo($links)




create_traveled_map = (cities) ->
  $map = $('<div />')
    .attr('id', 'traveled')

  map = new google.maps.Map($map[0], {
    minZoom: 2,
    zoom: 2,
    center: {lat: -34.397, lng: 150.644}
  })

  bounds = new google.maps.LatLngBounds()

  info_window = new google.maps.InfoWindow({})
  for o in cities
    pos = new google.maps.LatLng(o.city.latitude, o.city.longitude)
    bounds.extend(pos)
    marker = new google.maps.Marker({
      position: pos,
      map: map,
      title: o.city.name,
    })

    $content = $('<div />')
    $('<div />')
      .text("#{o.profiles.length} friend(s) traveled to #{o.city.name}")
      .appendTo($content)

    for profile in o.profiles
      $link = $('<a />')
        .addClass('avatar')
        .attr('href', "https://www.facebook.com/#{profile.id}")
        .attr('target', '_blank')
        .appendTo($content)

      $('<img />')
        .attr('src', profile.image)
        .appendTo($link)

    marker.content = $content[0]

    google.maps.event.addListener marker, 'mouseover', (o, b) ->
      info_window.setContent(this.content)
      info_window.open(map, this)

  map.fitBounds(bounds)
  return $map


create_section = (title, name, has_columns=true) ->
  $section = $('<div />')
    .attr('id', name)
    .addClass('section')
    .appendTo('#root')

  g_links.push {
    title: title
    name: name
  }

  $('<h1 />')
    .text(title)
    .appendTo($section)

  if !has_columns
    return $section

  $columns = $('<div />')
    .addClass('columns')
    .appendTo($section)

  return $columns

create_new_friend_story = (story) ->
  $story = create_base_story story
  if !$story
    return

  $story.addClass('contains_people')

  for o in story.profiles
    if !o.image
      continue

    $link = $('<a />')
      .attr('href', "http://www.facebook.com/#{o.id}")
      .attr('target', '_blank')
      .appendTo($story)

    $avatar = $('<img />')
      .addClass('avatar')
      .attr('src', o.image)
      .appendTo($link)

  return $story

create_place_story = (place) ->
  $story = create_base_story(place)
  if !$story
    return

  $story.addClass('contains_people')

  $avatars = $('<div />')
    .addClass('avatars')
    .appendTo($story)

  for visit in place.visits
    story_id = place.visits[0].stories[0]
    $link = $('<a />')
      .attr('href', "https://www.facebook.com/#{story_id}")
      .attr('target', '_blank')
      .appendTo($avatars)

    $avatar = $('<img />')
      .addClass('avatar')
      .attr('src', visit.profile.image)
      .appendTo($link)

  return $story

create_minutiae_story = (story) ->
  $cell = create_cell(story)
    .addClass('contains_people')

  $minutiae = $('<div />')
    .addClass('minutiae')
    .appendTo($cell)

  $('<img />')
    .attr('src', story.icon_url)
    .appendTo($minutiae)

  $('<div />')
    .text(story.minutiae_name)
    .appendTo($minutiae)

  for o in story.objects
    if !o.owner
      continue

    $link = $('<a />')
      .attr('href', o.permalink)
      .attr('target', '_blank')
      .appendTo($cell)

    $avatar = $('<img />')
      .addClass('avatar')
      .attr('src', o.owner.image)
      .appendTo($link)

    if o.message
      $link.addClass('has_message')
      $('<div />')
        .addClass('message')
        .text(o.message)
        .appendTo($link)

  return $cell


create_base_story = (story) ->
  if !story.message && !story.image && !story.title
    return

  $cell = create_cell(story)
  if story.title
    $('<div />')
      .addClass('title')
      .text(story.title)
      .appendTo($cell)

  if story.time
    $('<div />')
      .addClass('time')
      .text(moment.unix(story.time).format("MMMM Do"))
      .appendTo($cell)

  if story.image
    $('<img />')
      .addClass('main_image')
      .attr('src', story.image)
      .attr('width', '280px')
      .appendTo($cell)

  if !story.message && !story.owner
    return $cell

  $left = $('<div />')
    .addClass('left')
    .appendTo($cell)

  $right = $('<div />')
    .addClass('right')
    .appendTo($cell)

  if story.owner?.image
    $img = $('<img />')
      .addClass('avatar')
      .attr('src', story.owner.image)
      .appendTo($left)

  if story.owner?.name
    $('<div />')
      .addClass('name')
      .text(story.owner.name)
      .appendTo($right)

  if story.message
    $('<div />')
      .addClass('snippet')
      .text(story.message)
      .appendTo($right)

  return $cell


create_cell = (story) ->
  if story.permalink
    return $('<a />')
      .addClass('cell')
      .attr('data-id', story.id || '0')
      .attr('href', story.permalink)
      .attr('target', '_blank')
  else
    return $('<div />')
      .addClass('cell')



