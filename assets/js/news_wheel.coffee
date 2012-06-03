columns = 5
padding = 10
max_images = 100
width = Math.max(800, $(window).width() - 20)
column_width = (width / columns) - (padding * 2)

$ ->
  root = d3.select('#root').style('width', "#{width}px")

  d3.json '/data/news_data.json', (news) ->
    # Transform news data to what we want
    news = _.chain(news).sortBy((n) -> moment(n.date)).reverse()
      .map((n) ->
        params = if n.summary then _.chain(n.summary.entities) else _.chain(n.params).flatten()
        {
          event: n
          date: moment(n.date)
          headline: n.headline
          topic_images: params.map((p) -> p.topic_images && get_image(p.topic_images[0], 200)).compact().first(3).value()
          topic_names: params.map((p) -> p.topic?.name).compact().value()
          event_image: _.chain(n.images).map((i) -> get_image(i, 400)).compact().value()[0]
        })
      .filter((n) -> n.event_image && n.topic_images.length).uniq((n) -> n.event_image.url)

    # Layout
    last_from_now = null
    c_pos = []; _(column_width).times -> c_pos.push(10) # Initialize column Y coordinates
    news.each((n, i) ->
        # TODO: treat each column as a bucket and fir the next item into the shallowest one
        c_i = (i % columns)

        if n.date.fromNow() != last_from_now
          show_from_now = true
          last_from_now = n.date.fromNow()

        _(n).extend
          x: (c_i * (column_width + (padding * 2)) + 10)
          y: c_pos[c_i]
          show_from_now: show_from_now

        size = n.event_image.size
        c_pos[c_i] += ((column_width / size[0]) * size[1]) + padding + 110
        c_pos[c_i] += 60 if show_from_now
      )

    # construct cells
    root.selectAll('div').data(news.first(max_images).value()).enter().append('div').call(construct_image_cells)

construct_image_cells = ->
  @attr('class', 'cell').style('left', (d) -> "#{d.x}px").style('top', (d) -> "#{d.y}px").style('width', "#{column_width}px")

  # main body
  @append('div').attr('class', 'from_now').text((d) -> if d.show_from_now then d.date.fromNow() else null)
  @append('div').attr('class', 'headline')
    .append('a').text((d) -> d.headline).attr('target', 'blank').attr('href', (d) -> "http://wavii.com/news/#{d.event.news_event_id}")

  @append('img').attr('class', 'event').attr('src', (d) -> d.event_image.url).attr('width', column_width)

  # topic images and text
  @append('div').selectAll('img').data((d) -> d.topic_images).enter()
      .append('img').attr('class', 'topic').attr('src', (d) -> d.url)
      .attr('width', (d) -> Math.floor((d.size[0] * 50) / d.size[1]) + 'px')
  @append('div').attr('class', 'actors').text((d) -> ("Starring: " + d.topic_names.join(', ')))

# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width) ->
  images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  images.find((i) -> i.size[0] >= width).value() || images.last().value()
