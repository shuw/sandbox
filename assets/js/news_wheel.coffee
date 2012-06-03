columns = 5
padding = 20
max_images = 10
width = Math.max(800, $(window).width() - 40)
column_width = (width / columns) - (padding * 2)

$ ->
  root = d3.select('#root').style('width', "#{width}px")

  d3.json '/data/news_data.json', (news) ->
    get_image = (generic_image, width) ->
      images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])

      # First tries to find an image equal or bigger than requested,
      # otherwise, settles for a slightly smaller one
      images.find((i) -> i.size[0] >= width).value() || images.last().value()

    # Transform news data to what we want
    news = _.chain(news)
      .sortBy((n) -> moment(n.date))
      .reverse()
      .map((n) ->
        params = if n.summary then _.chain(n.summary.entities) else _.chain(n.params).flatten()
        {
          event: n
          date: moment(n.date)
          headline: n.headline
          topic_images: params.map((p) -> p.topic_images && get_image(p.topic_images[0], 200)).compact().first(4).value()
          topic_names: params.map((p) -> p.topic?.name).compact().value()
          event_image: _.chain(n.images).map((i) -> get_image(i, 400)).compact().value()[0]
        })
      .filter((n) -> n.event_image && n.topic_images.length)
      .uniq((n) -> n.event_image.url)

    # Layout
    c_pos = []
    _(column_width).times -> c_pos.push(10) # Initialize y coordinates
    news.each((n, i) ->
        # naively just layout events in stacked columns
        c_i = (i % columns)

        _(n).extend
          x: (c_i * (column_width + padding) + 10)
          y: c_pos[c_i]

        size = n.event_image.size
        c_pos[c_i] += ((column_width / size[0]) * size[1]) + padding + 70
      )

    root.selectAll('div')
      .data(news.first(max_images).value())
      .enter()
        .append('div')
        .attr('class', 'cell')
        .call(construct_image_cells)


construct_image_cells = ->
  @style('left', (d) -> "#{d.x}px")
    .style('top', (d) -> "#{d.y}px")

  @append('img')
    .attr('src', (d) -> d.event_image.url)
    .attr('width', column_width)

  @append('div').selectAll('img')
    .data((d) -> d.topic_images)
    .enter()
      .append('img')
      .attr('src', (d) -> d.url)
      .attr('width', "50px")
      .style('padding-right', "20px")

  @append('div')
    .attr('class', 'actors')
    .text((d) -> ("Starring: " + d.topic_names.join(', ')))
    .style('width', "#{column_width}px")
