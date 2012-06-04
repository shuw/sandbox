columns = 5
padding = 10
max_images = 1000
width = Math.max(800, $(window).width() - 20)
column_width = (width / columns) - (padding * 2)

root = null
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

    relation_types = news
      .groupBy((n) -> n.event.relation_type)
      .sortBy((events, relation_type) -> events.length)
      .map((events) -> { relation_type: events[0].event.relation_type, size: Math.min(max_images, events.length)})
      .union([{relation_type: "all", size: Math.min(max_images, news.size().value())}])
      .reverse().first(7).value()

    d3.select('#filters').selectAll('button')
      .data(relation_types)
      .enter()
        .append('button')
        .text((d) -> "#{d.relation_type} (#{d.size})")
        .on('click', (d) ->
          draw(news.filter((n) -> d.relation_type == 'all' || d.relation_type == n.event.relation_type))
        )

    draw(news)

draw = (news) ->
  apply_layout(news)

  # construct cells
  cells = root.selectAll('div.cell').data(news.first(max_images).value(), (d) -> d.event.news_event_id)
  cells.enter().append('div').call(construct_image_cells).call(update_positions)
  cells.exit().transition().duration(1500).style('opacity', 0)

  # handle layout changes of existing elements
  cells.transition().duration(1500).call(update_positions).style('opacity', 1)


apply_layout = (news) ->
  # Layout
  last_from_now = null
  c_pos = []; _(column_width).times -> c_pos.push(10) # Initialize column Y coordinates

  news.each((n, i) ->
      # TODO: treat each column as a bucket and fir the next item into the shallowest one
      c_i = (i % columns)

      if n.date.fromNow() != last_from_now
        show_from_now = true
        last_from_now = n.date.fromNow()

      n.x = (c_i * (column_width + (padding * 2)) + 10)
      n.y = c_pos[c_i]
      n.show_from_now = show_from_now

      size = n.event_image.size
      c_pos[c_i] += ((column_width / size[0]) * size[1]) + padding + 110
      c_pos[c_i] += 60 if show_from_now
    )
  news

update_positions = (sel) ->
  @style('left', (d) -> "#{d.x}px")
    .style('top', (d) -> "#{d.y}px")
    .style('width', "#{column_width}px")
    .selectAll('.from_now')
    .style('display', (d) -> if d.show_from_now then 'block' else 'none')

construct_image_cells = ->
  @attr('class', 'cell')
  # main body
  @append('div').attr('class', 'from_now').text((d) -> d.date.fromNow())
  @append('div').attr('class', 'headline')
    .append('a').text((d) -> d.headline)
    .attr('target', 'blank')
    .attr('href', (d) -> "http://wavii.com/news/#{d.event.news_event_id}")

  @append('a')
    .attr('target', 'blank')
    .attr('href', (d) -> "http://wavii.com/news/#{d.event.news_event_id}")
    .append('img').attr('class', 'event')
      .attr('src', (d) -> d.event_image.url).attr('width', column_width)

  # topic images and text
  @append('div').selectAll('img').data((d) -> d.topic_images).enter()
      .append('img').attr('class', 'topic').attr('src', (d) -> d.url)
      .attr('width', (d) -> Math.floor((d.size[0] * 50) / d.size[1]) + 'px')
  @append('div').attr('class', 'actors').text((d) -> ("Featuring: " + d.topic_names.join(', ')))

# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width) ->
  images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  images.find((i) -> i.size[0] >= width).value() || images.last().value()
