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

  d3.select('#relations').selectAll('.relation')
      .data(relations)
    .enter()
      .append('a')
      .attr('href', '#')
      .classed('relation', true)
      .text((d) -> "#{_(d.relation_type).humanize()} (#{d.events.length})")
      .on 'click', (d) ->
        _events = _.chain(d.events)
        draw_events(_events)
        draw_histogram(_events)

draw_events = (_events) ->
  # _events = _.chain(events)

  # _events.each (d) ->
  #   debugger


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
