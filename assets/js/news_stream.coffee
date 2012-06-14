_.mixin(_.string.exports())

max_cells = 2000

column_spacing = 16
column_width = 300
headline_line_height = 25
headline_line_avg_chars = 25

# a chained collection of all news
_all_news = _.chain([])

# window onhashchange handler
hash_change_handler = null

# Use webkit hw accelerated transitions or not?
webkit_accel = false # set in init
webkit_lineclamp = false # set in init

# date of the newest and oldest news event
newest_date = null
oldest_date = null

# url/path to data
data_path = null

# background fetcher state
background_fetcher_backoff_ms = 8000
background_fetcher_timer = null

# infinite scroll state
infinite_scroll_backoff_ms = 4000

# test node does not have background update or infinite scroll available
# as that requires the news server
test_mode = false

window.news_stream_init = (p_data_path, p_test_mode) ->
  test_mode = p_test_mode
  data_path = p_data_path
  calculate_element_sizes()

  webkit_accel = document.body.style.WebkitTransform?
  webkit_lineclamp = document.body.style.WebkitLineClamp?

  $(window).resize _.throttle(calculate_element_sizes, 500)

  if test_mode
    $(window).scroll ->
      infinite_scroll_backoff_ms = background_fetcher_backoff_ms = 4000
      reset_background_fetcher()
      infinite_scroll()

    reset_background_fetcher()

  newest_date = moment().utc()
  fetch_news(before_date: newest_date.format(), limit: Math.max(columns_count * 10, 20), purpose: 'append')


# Load and transform data
# ===============================================================


infinite_scroll = ->
  runway = $(document).height() - ($(window).scrollTop() + $(window).height())
  return unless runway < $(window).height() && oldest_date
  fetch_news
    before_date: oldest_date.format(),
    limit: columns_count * 5
    purpose: 'append'
    callback: (added_count) ->
      # now that we've added a few more items, make sure it was enough
      setTimeout(infinite_scroll, infinite_scroll_backoff_ms) if added_count
      infinite_scroll_backoff_ms *= 1.3


reset_background_fetcher = ->
  clearTimeout background_fetcher_timer

  background_fetcher_timer = setTimeout (->
    # grab news within a +/- 5 minute window from now
    before_date = moment().add('minutes', 5).utc()

    if $(window).scrollTop() < $(window).height()
      fetch_news
        after_date: newest_date.add('minutes', -10).format()
        before_date: before_date.format()
        background_poll: true
        limit: Math.max(columns_count * 5, 10)
        purpose: 'background_fetcher'

      newest_date = before_date

    reset_background_fetcher()
  ), background_fetcher_backoff_ms

  background_fetcher_backoff_ms *= 1.7


fetches_in_progress = {} # de-duplicates fetches by purpose
error_backoff_ms = 5000
fetch_news = (options) ->
  return if _all_news.size().value() > max_cells

  d3.select('#last_updated').text 'updating...'
  return if fetches_in_progress[options.purpose]
  fetches_in_progress[options.purpose] = true
  $.ajax data_path,
    data:
      before_date: options.before_date
      after_date: options.after_date
      limit: options.limit
    success: (news) ->
      error_backoff_ms = 5000
      d3.select('#last_updated').text 'Updated ' + moment().format('h:mm:ssa')
      fetches_in_progress[options.purpose] = false

      if test_mode
        news = _(news).first(100)

      original_size = _all_news.size().value()
      if news.length
        local_oldest = _.chain(news).map((d) -> moment(d.date)).min().value().utc()
        if !oldest_date || local_oldest < oldest_date
          oldest_date = local_oldest
        add_news(news)

      # invokes callback with number of new events added
      options.callback?(_all_news.size().value() - original_size)
    error: ->
      d3.select('#filters').text("having trouble contacting base, try again soon") unless options.background_poll
      d3.select('#last_updated').text ''
      _.delay((-> fetches_in_progress[options.purpose] = false), error_backoff_ms)
      error_backoff_ms *= 2


# takes an array of news and adds it to the global _all_news chained collection
add_news = (new_news) ->
  # Transform the new news data from the server and add it to our main collection
  _all_news = _all_news
    .union(_(new_news).map(transform_news_data))
    .uniq(false, (n) -> n.news_event_id)
    .sortBy((n) -> n.date).reverse()
    .filter((n) -> n.headline && (n.images.length || n.snippets.length))

  available_vertical_ids = _all_news.map((n) -> n.vertical_ids).compact().flatten().uniq()
  _verticals = _.chain([
    { id: 'all', name: 'All' },
    { id: 3, name: 'Business' },
    { id: 2, name: 'Technology' },
    { id: 1, name: 'Entertainment' },
    { id: 4, name: 'Politics' }
  ]).filter((v) -> v.id == 'all' || available_vertical_ids.include(v.id).value() )

  filters = d3.select('#filters')
    .text('')
    .selectAll('a')
    .data(_verticals.value())
  filters.enter()
    .append('a')
    .text((d) -> d.name)
    .attr('href', (d) -> "##{d.name.toLowerCase()}")
  filters.exit()
    .style('opacity', 0)
    .transition().duration(750).remove()

  # update news with filter selected by current location hash, then listen for further hash changes
  (filter_and_update = ->
    vertical_id = _verticals.filter((v) -> "##{v.name.toLowerCase()}" == location.hash).first().value()?.id || 'all'
    filters.classed('active', (d) -> d.id == vertical_id)
    news = _all_news.filter((n) -> vertical_id == 'all' || _.include(n.vertical_ids, vertical_id))
    update_cells(news)
  )()

  # update hash listener
  $(window).off 'hashchange', hash_change_handler
  hash_change_handler = $(window).on 'hashchange', filter_and_update


# get news_data into the format we want to bind to DOM using D3
transform_news_data = (n) ->
  # saturate params with their param name (i.e. 'location', 'person')
  _(n.params).each (params, key) ->
    if key != 'left_pkey' && key != 'right_pkey'
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
      })
    .value()

  # only show the first image OR the first snippet
  images = _.chain(n.images).map((i) -> get_image(i, column_width - 30)).compact().first(1).value()
  snippets = if images.length then [] else _.chain(n.articles).filter((a) -> a.surrounding_sentences?).compact().first(1).value()

  {
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


# UI concerns
# ===============================================================


# calculate based on window width
page_margin = 0; viewpoint_width = 0; columns_count = 0;
calculate_element_sizes = ->
  viewpoint_width = Math.max( Math.floor($(window).width() * 0.92),  320)
  columns_count = Math.floor viewpoint_width / (column_width + column_spacing)
  columns_count = Math.max(Math.min(columns_count, 5), 1)

  # page margin is the spacing on the left and right sides of the main feed
  page_margin = Math.max(Math.floor(
    (
      $(window).width() -
      (
        # subtract columns
        (columns_count * column_width) +
        # subtract spacing between columns
        ((columns_count - 1) * column_spacing)
      )
    ) / 2
  ), 10)

  d3.select('body').classed('narrow', $(window).width() <= 500)
  update_cells()


# updates the cells on screen given chained news collection
# if news not passed in, then will simply update the layout
news_in_cells = null
update_cells = (news) ->
  news_in_cells = news if news
  return unless news_in_cells

  apply_layout(news_in_cells)

  # construct cells
  cells = d3.select('#root').selectAll('.cell').data(news_in_cells.first(max_cells).value(), (d) -> d.news_event_id)
  cells.enter().append('div').call(construct_cells).call -> _.defer => @classed('visible', true)
  cells.exit().classed('visible', false).transition().duration(750).remove()
  cells.call ->
    if webkit_accel
      @style('-webkit-transform', (d) -> "translate3d(#{d.x}px, #{d.y}px, 0)")
    else
      @style('left', (d) -> "#{d.x}px").style('top', (d) -> "#{d.y}px")

    @selectAll('.from_now')
      .style('display', (d) -> if d.show_from_now then 'block' else 'none')



# adds layout coordinates to chained collection of news
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
      from_now_header_height = 50
      new_pos = _(c_pos).max() + (if i then 25 else 0) # add 25px between date clusters
      c_pos = _(c_pos).map (v, i) -> new_pos + (if i then from_now_header_height else 0)
      column = pos: c_pos[0], index: 0

    size_current += 1
    column = _.chain(c_pos).map((v, i) -> {pos: v, index: i}).min((d) -> d.pos).value()

    _(n).extend
      x: column.index * (column_width + column_spacing) + page_margin
      y: column.pos
      show_from_now: show_from_now

    if n.images.length
      height_of_cell = n.images[0].size[1] + 10
    else
      height_of_cell = 175 # height of snippet

    height_of_cell += n.headline_lines * headline_line_height
    height_of_cell += from_now_header_height if show_from_now
    height_of_cell += n.topics.length * 60
    height_of_cell += 70 # buffer misc padding margins

    c_pos[column.index] += height_of_cell
  )
  news


construct_cells = ->
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
      .text((d) ->
        if webkit_lineclamp
            d.headline
        else
          _(d.headline).prune(d.headline_lines * headline_line_avg_chars)
      )
      .attr('title', (d) -> d.headline)
      .attr('href', (d) -> "https://wavii.com/news/#{d.news_event_id}")
  content.append('div').classed('date', true)
    .text((d) -> d.date.format("h:mma, dddd M/DD"))

  slot_main = content.append('a')
    .attr('href', (d) -> "https://wavii.com/news/#{d.news_event_id}")

  # snippet
  slot_main.selectAll('.snippet').data((d) -> d.snippets).enter()
    .append('div')
      .classed('snippet', true)
      .text (d) ->
        snippet = "#{d.source} - “#{d.surrounding_sentences}”"
        if webkit_lineclamp then snippet else _(snippet).prune(250)

  # event image
  slot_main.selectAll('img.event').data((d) -> d.images).enter()
    .append('img')
      .classed('event', true)
      .attr('src', (d) -> d.url)
      .attr('width', (d) -> d.size[0])
      .attr('height', (d) -> d.size[1])

  # create partcipant elements for each topic
  content.append('div')
    .classed('participants', true)
    .selectAll('div.participant').data((d) -> d.topics).enter()
      .append('div')
        .classed('participant', true)
        .call ->
          @append('a')
            .classed('avatar', true)
            .attr('href', (d) -> "https://wavii.com/topics/#{d.topic_id}")
            .append('img')
              .attr('src', (d) -> d.image.url)
              .attr('width', (d) -> "#{d.image.size[0]}px")
              .attr('height', (d) -> "#{d.image.size[1]}px")
          @append('a')
            .classed('name', true)
            .attr('href', (d) -> "https://wavii.com/topics/#{d.topic_id}")
            .text((d) -> d.topic.name)
          @append('p')
            .classed('param_name', true)
            .text((d) -> d.param_name && d.param_name.replace(/_/g, ' '))


# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width, height) ->
  _images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  image = _images.find((i) -> i.size[0] >= width).value() || _images.last().value()

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
