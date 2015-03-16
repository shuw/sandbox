DURATION = 60.0

friends_ = time_window_ = time_window_size_ = real_start_time_ = null
loop_ = $root_ = $time_ = null
time_text_ = null
friends_shown_ = []

window.got_data = (friends) ->
  $ ->
    $('#loading').hide()
    $root_ = $('#root')
    $time_ = $('#time')

    time_window_ = [
      Math.max(
        friends[0].time,
        friends[3].time - 3600 * 24 * 60,
      ),
      friends[friends.length - 1].time
    ]
    time_window_size_ = time_window_[1] - time_window_[0]

    friends_ = friends
    real_start_time_ = moment().valueOf() / 1000.0
    loop_ = setInterval refresh, 50
    $('#song')[0].play()
    _.delay(
      -> $root_
        .css('transform', 'scale3d(0.6, 0.6, 0.6)')
        .css('top', '200px')
        .css('left', '400px'),
      100,
    )


spiral = (X, Y) ->
  positions = []
  x = y = 0
  dx = 0
  dy = -1
  max = Math.pow(Math.max(X, Y), 2)
  for i in [0..max]
    if (-X / 2 < x <= X / 2) && (-Y / 2 < y <= Y / 2)
      positions.push [x, y]

    if x == y || (x < 0 && x == -y) || (x > 0 && x == 1 - y)
      [dx, dy] = [-dy, dx]
    [x, y] = [x + dx, y + dy]

  return positions

spiral_positions_ = spiral(30, 15)


refresh = ->
  real_time = moment().valueOf() / 1000.0

  fraction = (real_time - real_start_time_) / DURATION
  fraction = Math.pow(fraction, 2.0)
  if fraction > 1.0
    clearInterval loop_
    return

  story_time = time_window_[0] + (time_window_size_ * fraction)

  for i, f of friends_
    if f.time > story_time
      break
    add_friend f

  friends_ = friends_.slice i

  for o in friends_shown_
    update_friend o, story_time, real_time

  time_text = moment(story_time * 1000.0).format("YYYY MMM")
  if time_text != time_text_
    time_text_ = time_text
    $time_.text  time_text_


add_friend = (f) =>
  if friends_shown_.length == 0
    pos = 0
  else
    pos = Math.min(
      Math.random() * (3 + friends_shown_.length * 0.5),
      spiral_positions_.length - 1)

  position = spiral_positions_.splice(pos, 1)[0]
  if !position
    return

  [x, y] = position
  x += 0
  y += 0

  $node = $('<div class="node" />')
    .css('left', "#{x * 102}px")
    .css('top', "#{y * 102}px")
    .appendTo($root_)

  _.delay(
    -> $node.css('transform', 'scale3d(1, 1, 1)'),
    100,
  )

  f.last_update = 0
  friends_shown_.push {
    f: f,
    $node: $node,
  }


update_friend = (o, story_time, real_time) ->
  for i, image of o.f.images
    if image.time > story_time
      break

  if real_time - o.f.last_update > 2.0 &&
     o.last_image_url != image.url
    o.f.last_update = real_time
    o.last_image_url = image.url
    $img = $('<img />')
      .attr('src', image.url)
      .appendTo(o.$node)
    _.delay(
      -> $img.css('opacity', 1.0),
      50 + Math.random() * 100,
    );
