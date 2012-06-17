width = 1000
height = 300

_.mixin(_.string.exports())

_all_events = _.chain([])

svg = null

window.story_init = (p_data_path, p_test_mode) ->
  svg = d3.select("#chart")
    .append("svg")
    .attr("width", width)
    .attr("height", height)


  $.ajax p_data_path, success: got_data

got_data = (events) ->
  _all_events = _.chain(events)
    .filter((d) -> d.relation_type != 'summary')
    .map((d) ->
      {
        data: d
        id: d.news_event_id
        relation_type: d.relation_type
        date: moment(d.date)
        topics: topics = (if d.summary then _(d.summary.entities) else _.chain(d.params).flatten().value())
      }
    )
    .sortBy((d) -> d.date)

  draw_relations()


draw_relations = ->
  relations = _all_events.groupBy('relation_type').map((events, relation_type) -> {
      events: events,
      relation_type: relation_type
    })
    .sortBy((d) -> d.events.length)
    .reverse()
    .take(10)
    .value()

  select = (relation) ->
    _events = _.chain(relation.events)
    draw_events(_events)
    draw_histogram(_events)

  d3.select('#relations').selectAll('.relation')
      .data(relations)
    .enter()
      .append('a')
      .attr('href', '#')
      .classed('relation', true)
      .text((d) -> "#{_(d.relation_type).humanize()} (#{d.events.length})")
      .on 'click', select

  select(relations[0]) if relations.length



draw_events = (_events) ->
  # _events = _.chain(events)

  topics = _events
    .map((e) -> e.topics)
    .flatten()
    .select((t) -> t.label?)
    .groupBy('label')
    .map((topics, label) ->
      topic_images = topics[0].topic_images
      image = (topic_images && get_image(topic_images[0], 100, 100)) || {
        url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png',
        size: [100, 100]
      }

      {
        occurences: topics.length
        image: image
        label: label
      })
    .sortBy((d) -> d.occurences)
    .reverse()
    .value()

  divs = d3.select('#events').selectAll('.topic')
      .data(topics, (d) -> d.label)
  divs.enter()
      .append('div')
        .classed('topic', true)
        .call ->
          @append('img')
            .attr('src', (d) -> d.image.url)
            .attr('width', (d) -> d.image.size[0])
            .attr('height', (d) -> d.image.size[1])
          @append('div')
            .text((d) -> "#{d.label} (#{d.occurences})")
  divs.exit()
      .remove()



draw_histogram = (_events) ->
  by_date = _events.groupBy((d) -> d.date.format('MM/YY')).value()

  months = []
  oldest = _all_events.first().value().date.clone()
  newest = _all_events.last().value().date
  while oldest < newest
    months.push oldest.format('MM/YY')
    oldest = oldest.add('months', 1)

  x = d3.scale.ordinal()
    .domain(months)
    .rangeRoundBands([0, width])

  y = d3.scale.linear()
    .domain([0, _.chain(by_date).map((d) -> d.length).max().value()])
    .range([0, height])

  recs = svg.selectAll("rect")
      .data(months, (d) -> d)
  recs.enter().append("rect")
      .attr("width", x.rangeBand())
      .attr("x", (d) -> x(d))
      .attr("height", height)

  recs.exit()
      .remove()
  recs.transition().duration(500)
      .attr("y", (d) -> height - y((by_date[d] || []).length))
      .attr("height", (d) -> y((by_date[d] || []).length))


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
