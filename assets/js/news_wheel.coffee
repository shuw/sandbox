columns = 5
padding = 20
max_images = 50
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
          date: moment(n.date)
          headline: n.headline
          topic_images: params.map((p) -> p.topic_images && get_image(p.topic_images[0], 200)).compact().value()
          event_image: _.chain(n.images).map((i) -> get_image(i, 400)).compact().value()[0]
        })
      .filter((n) -> n.event_image && n.topic_images.length)
      .uniq((n) -> n.event_image.url)

    # Layout
    c_pos = []
    _(column_width).times -> c_pos.push(0)
    news.each((n, i) ->
        c_i = (i % columns)
        _(n).extend
          x: c_i * (column_width + padding)
          y: c_pos[c_i]

        size = n.event_image.size
        c_pos[c_i] += ((column_width / size[0]) * size[1]) + padding
      )

    root.selectAll('div')
      .data(news.first(max_images).value())
      .enter()
        .append('img')
        .attr('class', 'cell')
        .attr('src', (d) -> d.event_image.url)
        .attr('width', column_width)
        .style('left', (d) -> "#{d.x}px")
        .style('top', (d) -> "#{d.y}px")
