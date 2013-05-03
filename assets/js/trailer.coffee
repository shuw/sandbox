_.mixin(_.string.exports())

# TODO:
# Credits (you, your friends)
# How much time do you have dialog
# Important Friends units

WIDTH = 700
HEIGHT = 400

g_startTime = null
g_sceneIndex = null

_.mixin(_.string.exports())

g_user_id = null
window.trailerInit = ->
  g_user_id = utils.getQuery('user')
  $.ajax "/data/#{g_user_id}_timeline.json",
    success: (data) -> gotTimeline(data)
    error: ->
      $('#loading')
        .text('Loading user data. This could take a while, do not refresh the page!')
      $.post "/trailer/create", {user: g_user_id}

      poll = setInterval((->
        $('#loading').text($('#loading').text() + '.')
        $.ajax "/data/#{g_user_id}_timeline.json",
          success: (data) ->
            return unless data
            $('#stage').text('')
            clearInterval(poll)
            gotTimeline(data)
      ), 500)


g_scenes = null
g_duration = null
g_friends = null
gotTimeline = (data) ->
  $.ajax "/data/#{g_user_id}_friends.json",
    success: (friends) ->
      g_friends = friends
      chooseDuration(data)
    error: ->
      g_friends = []
      chooseDuration(data)

chooseDuration = (data) ->
  $('#loading').addClass('hidden')
  $('#chooser').removeClass('hidden')
  $options = $('#chooser .option')
  $options
    .on('hover', ->
      $options.removeClass('selected')
      $(@).addClass('selected')
    )
    .on('click', ->
      seconds = $(@).data('seconds')
      duration_chosen(seconds)
    )

  started = false
  setTimeout((->
    unless started
      seconds = $('#chooser .option.selected').data('seconds')
      duration_chosen(seconds)
  ), 3000)

  duration_chosen = (seconds) ->
    started = true
    $('#chooser').addClass('hidden')
    $('#trailer').removeClass('hidden')
    g_scenes = createScenes(seconds * 1000, data)
    last_scene = g_scenes[g_scenes.length - 1]
    g_duration = last_scene.start_time + last_scene.duration
    drawControls()
    start()


g_scene_ms = null
createScenes = (approx_duration_ms, data) ->
  by_type = _(data.units).groupBy((u) -> u.unit_type)

  rankAndSort = (units, num_to_take) ->
    _(units).chain()
      .sortBy((u) -> -u.score)
      .take(num_to_take)
      .sortBy((u) -> u.start_time)
      .value()

  photos = _.union(
    by_type.TAGGED_PHOTO || [],
    by_type.ADD_SINGLE_PHOTO || [],
    by_type.COVER_PHOTO_CHANGE || [],
  )

  g_scene_ms = if approx_duration_ms < 60000 then 3000 else 6000

  num_photos_to_show = Math.min(Math.floor(approx_duration_ms / g_scene_ms), photos.length)
  approx_duration_ms = num_photos_to_show * g_scene_ms
  photos = rankAndSort(photos, num_photos_to_show)

  status_updates = rankAndSort(by_type.STATUS_UPDATE, 100)
  experiences = rankAndSort(by_type.EXPERIENCE, 30)

  mainScenes = getMainScenes(data.user, photos, status_updates, experiences)
  mainScenes


getControlPosition = (time) ->
  progress = Math.min((time) / g_duration, 1)
  position = WIDTH * progress
  position


g_currSceneTime = null
drawControls = () ->
  $controls = $('#controls')
    .on('click', (e) ->
      $el = $(@)
      progress = (e.pageX - $el.offset().left) / WIDTH
      g_startTime = moment().valueOf() - (progress * g_duration)
      g_sceneIndex = 0
      g_currSceneTime = null
      $('#stage').empty()
      $('#header time').text('')
    )
  for scene in g_scenes
    color = null
    if scene.is_year_marker
      color = "#0F1789"
    else if scene.is_main_scene
      color = "#999"
    else if scene.type == 'experience'
      color = "#C2FACD"
    else if scene.type == 'credits'
      color = '#000'
    else
      color = "#BBB"

    continue unless color

    $('<div class="marker"></div>')
      .css(
        'left': getControlPosition(scene.start_time),
        'backgroundColor': color
      )
      .appendTo($controls)


updateControls = (curr_time) ->
  $('#controls .selector')
    .css('left', getControlPosition(curr_time) - 5)


getMainScenes = (user, main_units, status_updates, experiences) ->
  scenes = []
  current_year = null

  moment.unix(user.anchorTime).year()
  born_year = moment.unix(user.anchorTime).year()

  # Name
  scenes.push
    type: 'text', start_time: 1000, duration: g_scene_ms * 0.6, title: user.name,
    subtitle: "since #{born_year}"

  # Profile pic
  scenes.push
    type: 'photo'
    transition: 'photoRightLeft'
    start_time: 0
    duration: g_scene_ms
    image: user.image

  status_update_index = 0
  experience_index = 0

  current_year = born_year
  start_time = g_scene_ms

  i = 0
  while i < main_units.length
    unit = main_units[i]
    next_unit = main_units[Math.min(i + 1, main_units.length - 1)]
    i++

    year = moment.unix(unit.start_time).year()
    if year != current_year
      scenes.push
        background_color: "#222"
        is_year_marker: true
        type: 'text'
        start_time: start_time
        duration: g_scene_ms / 2
        title: year
      current_year = year
      start_time += g_scene_ms / 2

    # TODO: add more types of transitions
    rand = Math.floor(Math.random() * 10000000) % 2
    if rand == 0
      transition = 'photoLeftRight'
    else
      transition = 'photoRightLeft'

    if not unit.images
      continue

    scenes.push
      is_main_scene: true
      type: 'photo'
      transition: transition
      start_time: start_time
      duration: g_scene_ms * 1.4
      message: unit.message
      image: unit.images[0]
      event_time: unit.start_time

    experiences_in_main_scene = 0
    experience_start_time = start_time + g_scene_ms / 6
    while true
      if experience_index >= experiences.length
        break

      experience = experiences[experience_index]
      if experience.start_time >= next_unit.start_time
        break

      if moment.unix(experience.start_time).year() > current_year
        break

      experience_index += 1
      if moment.unix(experience.start_time).year() < current_year ||
         !experience.icon
        continue
      else
        scenes.push
          type: 'experience'
          event_time: experience.start_time
          experience: experience
          start_time: experience_start_time
          duration: g_scene_ms
          ordinal: experiences_in_main_scene

        experiences_in_main_scene += 1
        experience_start_time += g_scene_ms/ 6
        if secondary_start_time + (g_scene_ms / 2) > start_time + g_scene_ms
          break

    secondary_start_time = start_time + 2000
    status_update_in_main_scene = 0

    # show some status updates with each main scene
    while true
      if status_update_index >= status_updates.length
        break

      status_update = status_updates[status_update_index]
      if status_update.start_time >= next_unit.start_time
        break

      if moment.unix(status_update.start_time).year() > current_year
        break
      status_update_index += 1
      if moment.unix(status_update.start_time).year() < current_year
        continue
      else
        scenes.push
          type: 'status_update'
          event_time: status_update.start_time
          start_time: secondary_start_time
          duration: g_scene_ms / 2
          message: status_update.message
          ordinal: status_update_in_main_scene

        secondary_start_time += g_scene_ms / 6
        status_update_in_main_scene += 1
        if secondary_start_time + g_scene_ms / 2  > start_time + g_scene_ms
          break

    start_time += g_scene_ms

  if g_friends?.length
    scenes.push
      type: 'credits'
      friends: _(g_friends).take(30)
      start_time: start_time
      duration: g_scene_ms * 2

  _(scenes).sortBy((s) -> s.start_time)


g_drawInterval = null
$stage = null
start = ->
  g_sceneIndex = 0
  $stage = $('#stage')
  g_startTime = moment().valueOf()

  if utils.getQuery('song') == 'remember'
    $('<iframe width="420" height="315" src="http://www.youtube.com/embed/nSz16ngdsG0?autoplay=1" frameborder="0" allowfullscreen></iframe>')
      .css(opacity: 0)
      .appendTo('body')

  stop()
  g_drawInterval = setInterval(draw, 1000 / 30)

stop = -> clearInterval(g_drawInterval)

draw = ->
  curr_time = moment().valueOf() - g_startTime
  updateControls(curr_time)

  while g_sceneIndex < g_scenes.length
    scene = g_scenes[g_sceneIndex]
    if scene.start_time > curr_time
      break
    if scene.start_time + 100 > curr_time
      drawScene(scene)

    g_sceneIndex += 1

drawScene = (scene) ->
  if scene.event_time
    if !g_currSceneTime || scene.event_time > g_currSceneTime
      g_currSceneTime = scene.event_time
      $('#header time').text(
        moment.unix(scene.event_time).format("MM/DD/YYYY")
      )
  switch scene.type
    when 'photo' then drawPhotoScene(scene)
    when 'text' then drawTextScene(scene)
    when 'status_update' then drawStatusUpdateScene(scene)
    when 'experience' then drawExperienceScene(scene)
    when 'credits' then drawCreditsScene(scene)

drawCreditsScene = (scene) ->
  $credits = $('<div class="credits"><h1>Credits</h1></div>')
    .appendTo('#stage')
    .animate("credits", scene.duration)
  for i in [0..scene.friends.length - 1] by 1
    f = scene.friends[i]
    $(Mustache.render("""
      <div class="experience">
        <img class="profile_pic" width=50 height=50 src="{{profile_pic}}"></img>
        <div class="name">{{name}}</div>
      </div>
    """, f))
      .css(
        top: 80 + Math.floor(i / 3) * 100
        left: (i % 3) * 200
      )
      .appendTo($credits)

drawExperienceScene = (scene) ->
  is_left = scene.ordinal % 2 == 0
  $image = $(Mustache.render("""
      <div class="experience">
        <img width=50 height=50 src="http://www.facebook.com/{{icon}}"></img>
        <div>{{name}} {{description}} {{location}}</div>
      </div>
    """,
    scene.experience))
    .css(
      top: Math.floor(scene.ordinal / 2) * 100
      left: (if is_left then -210 else WIDTH + 10)
    )
    .animate("experience", scene.duration)
    .appendTo("#stage_container")

drawStatusUpdateScene = (scene) ->
  $("""<div class="status_update"></div>""")
    .text(_(scene.message).truncate(140))
    .css(
      top: Math.floor(scene.ordinal / 2) * 100
      left: (scene.ordinal % 2) * 500
    )
    .animate('textTitle', scene.duration, true)
    .appendTo('#status_updates')

drawTextScene = (scene) ->
  if scene.background_color
    $("""<div class="background"></div>""")
      .css('backgroundColor', scene.background_color)
      .animate('fadeInOut', scene.duration)
      .appendTo($stage)

  animateClass = if scene.is_year_marker then 'year' else 'textTitle'
  $text = $("""<div class="text_title"></div>""")
    .text(scene.title)
    .animate(animateClass, scene.duration, !scene.is_year_marker)
    .appendTo($stage)
  $text.addClass('shadow') unless scene.background_color

  if scene.subtitle
    $("""<div class="text_subtitle"></div>""")
      .text(scene.subtitle)
      .addClass('shadow')
      .animate('textTitle', scene.duration)
      .appendTo($stage)


PAN_WIDTH = 50
PAN_HEIGHT = 15
drawPhotoScene = (scene) ->
  return unless scene.image
  [width, height] = scale_image(scene.image, WIDTH + PAN_WIDTH, HEIGHT + PAN_HEIGHT, true)

  data =
    uri: scene.image.uri
    message: scene.message
    height: height
    width: width

  $image = $(Mustache.render(
      """<img class="main_photo" width={{width}} height={{height}} src={{uri}}> </img>""", data))
    .animate(scene.transition, scene.duration)
    .appendTo($stage)

  if (scene.message)
    $("""<div class="photo_message"></div>""")
      .text(scene.message)
      .animate('photoMessage', scene.duration * 0.8)
      .appendTo($stage)

jQuery.fn.animate = (animationName, duration, ease=false) ->
  # hack because webkitAnimationEnd is too delayed
  setTimeout((=> $(@).remove()), duration * 0.95)
  @.css(
    '-webkit-animation-timing-function': if ease then 'ease' else 'linear'
    '-webkit-animation-name': animationName
    '-webkit-animation-duration': "#{duration / 1000}s")
    .bind('webkitAnimationEnd', -> $(@).remove())
  @


# scale to fit in box
scale_image = (image, width, height, fill) ->
  if height
    width ||= image.width
    height ||= image.height
    if fill
      scale = Math.max(width / image.width, height / image.height)
    else
      scale = Math.min(width / image.width, height / image.height)
  else
    scale = width / image.width

  return [scale * image.width, scale * image.height]

window.stop = stop
