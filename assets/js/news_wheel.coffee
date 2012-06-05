# TODO:
# - layout topics verticalls and linked
# - set height on images so there is no jumping around
# - build API in Wavii frontend-website to get data in real time
# - infinite scroll
#
# UI Suggestions from Allen:
# > make sure headline is 2 lines (at least they can tell what news it is)
# > add border so each cluster is within it's own region (seem less scattered)
# > Need to be clear topic images are topics (or just move your Featuring: xxx line to above the topic images)
# > What do you think of a small [Follow] button below each topic unfollowed? quick way to add, and also signifies they are topics
# > or we can make a small pin when u hover over topic images and click on them = pin them (following them)


columns_count = 5
padding = 10
max_cells = 100
width = Math.max(800, $(window).width() - 20)
column_width = (width / columns_count) - (padding * 2)

# Use for demonstration purposes.... move all news events to recent and trickle in new news events
FAKE_REALTIME = false

root = null
filter_relation_type = 'all'

$ ->
  root = d3.select('#root').style('width', "#{width}px")

  d3.json '/data/news_data.json', (news) ->
    # Transform news data to what we want
    news = _.chain(news).sortBy((n) -> moment(n.date)).reverse()
      .map((n) ->
        topics = (if n.summary then _.chain(n.summary.entities) else _.chain(n.params).flatten())
          .filter((p) -> p.topic)
          .map((p) ->
            image = (p.topic_images && get_image(p.topic_images[0], 200)) || {
              url: 'http://wavii-shu.s3.amazonaws.com/images/topic_placeholder.png',
              size: [50, 50]
            }
            # Scale image to 50px
            scale = Math.min(50.0 / image.size[0], 50.0 / image.size[1])
            image.size = [scale * image.size[0], scale * image.size[1]]

            {
              topic_id: p.topic_id
              topic: p.topic
              image: image
            })
          .value()

        {
          event: n
          date: moment(n.date)
          headline: n.headline
          topics: topics,
          event_image: _.chain(n.images).map((i) -> get_image(i, 400)).compact().value()[0]
        })
      .filter((n) -> n.event_image).uniq((n) -> n.event_image.url)

    if FAKE_REALTIME
      trickle_in_news = news.first(10).reverse().value()
      news = news.rest(10)
      offset = moment() - news.first().value().date
      news.each (n) -> n.date = moment(n.date + offset)

      trickle = ->
        event = trickle_in_news.pop()
        if event
          event.date = moment()
          news = _.chain([event]).union(news.value())
          update(news)
        _.delay(trickle, (10 + (Math.random() * 15) - 7) * 1000)

      _.delay(trickle, 5000)

    relation_types = news
      .groupBy((n) -> n.event.relation_type)
      .sortBy((events, relation_type) -> events.length)
      .map((events) -> { relation_type: events[0].event.relation_type, size: Math.min(max_cells, events.length)})
      .union([{relation_type: "all", size: Math.min(max_cells, news.size().value())}])
      .reverse().first(7).value()

    d3.select('#filters').selectAll('button')
      .data(relation_types)
      .enter()
        .append('button')
        .text((d) -> "#{d.relation_type.replace(/_/g, ' ')} (#{d.size})")
        .on('click', (d) ->
          filter_relation_type = d.relation_type
          update(news)
        )

    update(news)

update = (news) ->
  news = news.filter((n) -> filter_relation_type == 'all' || filter_relation_type == n.event.relation_type)
  apply_layout(news)

  # construct cells
  cells = root.selectAll('div.cell').data(news.first(max_cells).value(), (d) -> d.event.news_event_id)
  cells.enter().append('div').call(construct_image_cells).call(update_positions)
  cells.exit().transition().duration(750).style('opacity', 0).remove()

  # handle layout changes of existing elements
  cells.transition().duration(1500).call(update_positions)


apply_layout = (news) ->
  from_now_prev = null
  size_current = Number.MAX_VALUE
  # treat each column as a bucket filled up to a y coordinate
  c_pos = []; _(columns_count).times -> c_pos.push(10) # Initialize column Y coordinates

  news.each((n, i) ->
      unless n.date.fromNow() == from_now_prev || size_current < (columns_count * 3)
        size_current = 0
        show_from_now = true
        from_now_prev = n.date.fromNow()

        # new date header, so align all columns and push
        from_now_header_height = 56
        new_pos = _(c_pos).max() + (if i then 50 else 0) # add 50px between date clusters
        c_pos = _(c_pos).map (v, i) -> new_pos + (if i then from_now_header_height else 0)
        column = pos: c_pos[0], index: 0

      size_current += 1
      column = _.chain(c_pos).map((v, i) -> {pos: v, index: i}).min((d) -> d.pos).value()

      _(n).extend
        x: column.index * (column_width + (padding * 2)) + 10
        y: column.pos
        show_from_now: show_from_now

      # push column by stretched image size + padding (to account for topic images)
      height_of_cell = (column_width * n.event_image.size[1]) / n.event_image.size[0] + 90
      height_of_cell += from_now_header_height if show_from_now

      height_of_cell += n.topics.length * 55

      c_pos[column.index] += height_of_cell
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
    .append('a')
    .text((d) -> d.headline)
    .attr('title', (d) -> d.headline)
    .attr('target', 'blank')
    .attr('href', (d) -> "http://wavii.com/news/be#{d.event.external_id}")
  @append('div').attr('class', 'date')
    .text((d) -> d.date.format("h:mm a, dddd M/YY"))

  # main image
  @append('a')
    .attr('target', 'blank')
    .attr('href', (d) -> "http://wavii.com/news/be#{d.event.external_id}")
    .append('img').attr('class', 'event')
      .attr('src', (d) -> d.event_image.url)
      .attr('width', column_width)


  # params.map((p) -> p.topic_images && get_image(p.topic_images[0], 200)).compact().first(3).value()
  # # topic images and text
  @append('div').selectAll('div.participant').data((d) -> d.topics).enter()
      .append('div')
      .attr('class', 'participant')
      .call(construct_participant)

  # @append('div').attr('class', 'actors').text((d) -> ("Featuring: " + d.topic_names.join(', ')))

construct_participant = (data) ->
  @selectAll('img')
    .data((d) -> if d.image then [d.image] else [])
    .enter()
      .append('img')
      .attr('src', (d) -> d.url)
      .attr('width', (d) -> "#{d.size[0]}px")
      .attr('height', (d) -> "#{d.size[1]}px")

  @append('p').text((d) -> d.topic.name)
  # params.map((p) -> p.topic_images && get_image(p.topic_images[0], 200)).compact().first(3).value()


# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width) ->
  images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  images.find((i) -> i.size[0] >= width).value() || images.last().value()
