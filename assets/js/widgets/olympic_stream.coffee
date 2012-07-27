class window.OlympicStream

  constructor: (root_selector) ->
    @root_selector = root_selector

    # Use webkit hw accelerated transitions or not?
    @webkit_accel = document.body.style.WebkitTransform?
    @webkit_lineclamp = document.body.style.WebkitLineClamp?

  # updates the cells on screen given a list of events
  # if events not passed in, then will simply update the layout
  update: (agg_events) ->
    # construct cells
    cells = d3.select(@root_selector).selectAll('.cell').data(agg_events, (d) -> d.news_event_id)
    cells.enter()
      .append('div')
      .call(@_construct_events)
      .call(-> _.defer => @classed('visible', true))
    cells.exit()
      .classed('visible', false).transition().duration(750).remove()

  _construct_events: ->
    debugger
    @classed('cell', true)
      .style('width', "#{column_width}px")
      .append('div')
        .classed('from_now', true)
        .text((d) -> d.date.fromNow())


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
