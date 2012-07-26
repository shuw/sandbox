column_spacing = 16
column_width = 300
headline_line_height = 25
headline_line_avg_chars = 25

# followed map
topic_id_followed_map = topic_id_followed_map || {}


class window.OlympicStream

  constructor: (root_selector) ->
    @root_selector = root_selector
    $(window).resize _.throttle((=> @_calculate_element_sizes()), 500)
    @news = []
    @_calculate_element_sizes()

    # Use webkit hw accelerated transitions or not?
    @webkit_accel = document.body.style.WebkitTransform?
    @webkit_lineclamp = document.body.style.WebkitLineClamp?

  # updates the cells on screen given a list of events
  # if events not passed in, then will simply update the layout
  update: (news) ->
    if news?
      @news = _(news).map (n) -> transform_news_data(n)

    @_apply_layout(@news)

    # construct cells
    cells = d3.select(@root_selector).selectAll('.cell').data(@news, (d) -> d.news_event_id)
    cells.enter().append('div').call(@_construct_cells).call -> _.defer => @classed('visible', true)
    cells.exit().classed('visible', false).transition().duration(750).remove()
    cells.call ->
      if @webkit_accel
        @style('-webkit-transform', (d) -> "translate3d(#{d.x}px, #{d.y}px, 0)")
      else
        @style('left', (d) -> "#{d.x}px").style('top', (d) -> "#{d.y}px")

      @selectAll('.from_now')
        .style('display', (d) -> if d.show_from_now then 'block' else 'none')


  _calculate_element_sizes: ->
    padding_left = $(@root_selector).offset().left
    console.log "PADDING_LEFT #{padding_left}"
    @viewpoint_width = Math.max( Math.floor(($(window).width() - padding_left) * 0.97),  320)
    @columns_count = Math.floor @viewpoint_width / (column_width + column_spacing)
    @columns_count = Math.max(Math.min(@columns_count, 10), 1)

    # page margin is the spacing on the left and right sides of the main feed
    @page_margin = 20

    d3.select('body').classed('narrow', $(window).width() <= 500)
    @update()


  # adds layout coordinates to chained collection of news
  _apply_layout: (news) ->
    from_now_prev = null
    size_current = Number.MAX_VALUE
    # treat each column as a bucket filled up to a y coordinate
    c_pos = []; _(@columns_count).times -> c_pos.push(10) # Initialize column Y coordinates

    _(news).chain().each((n, i) =>
      unless n.date.fromNow() == from_now_prev || size_current < (@columns_count * 3)
        size_current = 0
        show_from_now = true
        from_now_prev = n.date.fromNow()

        # new date header, so align all columns and push
        from_now_header_height = 50
        new_pos = _(c_pos).max() + (if i then 25 else 0) # add 25px between date clusters
        c_pos = _(c_pos).map (v, i) -> new_pos + (if i then from_now_header_height else 0)
        column = pos: c_pos[0], index: 0

      size_current += 1
      column = _.chain(c_pos).map((v, i) -> {pos: v, index: i}).min((d) -> d.pos).value()

      _(n).extend
        x: column.index * (column_width + column_spacing) + @page_margin
        y: column.pos
        show_from_now: show_from_now

      if n.images.length
        height_of_cell = n.images[0].size[1] + 10
      else
        height_of_cell = 175 # height of snippet

      height_of_cell += n.headline_lines * headline_line_height
      height_of_cell += from_now_header_height if show_from_now
      height_of_cell += n.topics.length * 60
      height_of_cell += 40 if n.reads.length
      height_of_cell += 70 # buffer misc padding margins

      c_pos[column.index] += height_of_cell
    )


  _construct_cells: ->
    @classed('cell', true)
      .style('width', "#{column_width}px")
      .append('div')
        .classed('from_now', true)
        .text((d) -> d.date.fromNow())

    content = @append('div').classed('content', true)
    content.append('div').classed('headline', true)
      .append('a')
        .style('-webkit-line-clamp', (d) -> d.headline_lines)
        .style('max-height', (d) -> d.headline_lines * headline_line_height)
        .html((d) ->
          if @webkit_lineclamp
              d.headline
          else
            _(d.headline).prune(d.headline_lines * headline_line_avg_chars)
        )
        .attr('title', (d) -> d.headline)
        .call(news_event_link)

    content.append('div').classed('date', true)
      .text((d) -> d.date.format("h:mma, dddd M/DD"))

    slot_main = content.append('a').call(news_event_link)

    # snippet
    slot_main.selectAll('.snippet').data((d) -> d.snippets).enter()
      .append('div')
        .classed('snippet', true)
        .text (d) ->
          snippet = "#{d.source} - “#{d.surrounding_sentences}”"
          if @webkit_lineclamp then snippet else _(snippet).prune(250)

    # event image
    slot_main.selectAll('img.event').data((d) -> d.images).enter()
      .append('img')
        .classed('event', true)
        .attr('src', (d) -> d.url)
        .attr('width', (d) -> d.size[0])
        .attr('height', (d) -> d.size[1])

    # social reads
    reads = content.append('div')
      .classed('reads', true)
      .classed('hidden', (d) -> d.reads.length == 0)
    reads.selectAll('.read').data((d) -> d.reads).enter()
      .append('a')
        .classed('read', true)
        .attr('href', (d) -> "/profile/#{d.user_id}")
        .attr('target', '_blank')
        .attr('title', (d) -> d.name)
        .append('img')
          .attr('src', (d) -> d.pic_url)
          .attr('height', 30)
          .attr('width', 30)
    reads.append('div')
      .classed('description', true)
      .text('READ THIS')

    # create partcipant elements for each topic
    content.append('div')
      .classed('participants', true)
      .selectAll('div.participant').data((d) -> d.topics).enter()
        .append('div')
          .classed('participant', true)
          .call ->
            @append('a')
              .classed('avatar', true)
              .call(topic_link)
              .append('img')
                .attr('src', (d) -> d.image.url)
                .attr('width', (d) -> "#{d.image.size[0]}px")
                .attr('height', (d) -> "#{d.image.size[1]}px")
            @append('a')
              .classed('name', true)
              .call(topic_link)
              .text((d) -> d.topic.name)
            @append('a')
              .classed('follow', true)
              .classed('disabled', (d) -> !d.can_follow)
              .attr('topic_id', (d) -> d.topic_id)
              .text('FOLLOW')
              .on 'click', (d) ->
                return window.location = '/sign_in' if g_options.anonymous
                $.ajax "topics/#{d.topic_id}/follow", dataType: 'jsonp', type: 'POST'
                topic_id_followed_map[d.topic_id] = true
                $("a.follow[topic_id=#{d.topic_id}]").hide()

            @append('p')
              .classed('param_name', true)
              .text((d) -> d.param_name && d.param_name.replace(/_/g, ' '))


# get news_data into the format we want to bind to DOM using D3
transform_news_data = (e) ->
  n = e.news_event

  # saturate params with their param name (i.e. 'location', 'person')
  _(n.params).each (params, key) ->
    unless _.str.include(key, 'pkey')
      _(params).each (p) -> p.param_name = key

  topics = (if n.summary then _.chain(n.summary.entities) else _.chain(n.params).flatten())
    .filter((p) -> p.topic)
    .map((p) ->
      image = (p.topic_images && get_image(p.topic_images[0], 40, 40)) || {
        url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png',
        size: [40, 40]
      }

      {
        param_name: p.param_name
        topic_id: p.topic_id
        topic: p.topic
        image: image
        can_follow: p.topic?.is_active? && !topic_id_followed_map[p.topic_id]?
      })
    .value()

  # only show the first image OR the first snippet
  images = _.chain(n.images).map((i) -> get_image(i, column_width - 30)).compact().first(1).value()
  snippets = if images.length then [] else _.chain(n.articles).filter((a) -> a.surrounding_sentences?).compact().first(1).value()

  {
    reads: _(n.reads || []).take(5)
    vertical_ids: n.vertical_ids
    relation_type: n.relation_type
    news_event_id: n.news_event_id
    date: moment(n.date)
    headline: n.headline
    topics: topics
    images: images
    snippets: snippets
    headline_lines: Math.ceil(n.headline.length / headline_line_avg_chars)
  }

news_event_link = ->
  @attr('href', (d) -> "/news/#{d.news_event_id}")
  @attr('target', '_blank')
  @on 'click', -> trackEvent 'experiments/stream/content', 'click', target: 'news_event'


topic_link = ->
  @attr('href', (d) -> "/topics/#{d.topic_id}")
  @attr('target', '_blank')
  @on 'click', -> trackEvent 'experiments/stream/content', 'click', target: 'topic'


# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width, height) ->
  images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  image = images.find((i) -> i.size[0] >= width).value() || images.last().value()

  if image
    if height
      # scale to fit in box
      width ||= image.size[0]
      height ||= image.size[1]
      scale = Math.min(width / image.size[0], height / image.size[1])
    else
      scale = width / image.size[0]

    image.size = [scale * image.size[0], scale * image.size[1]]

  image
