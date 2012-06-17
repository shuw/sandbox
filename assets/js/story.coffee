width = 1000
height = 300


_all_events = _.chain([])

window.story_init = (p_data_path, p_test_mode) ->
  $.ajax p_data_path, success: got_data

got_data = (events) ->
  _all_events = _.chain(events).map((d) ->
    {
      id: d.news_event_id,
      relation_type: d.relation_type
      date: moment(d.date)
    })
    .sortBy((d) -> d.date)

  draw_relations()


  draw_histogram()


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
      .classed('relation', true)
      .text((d) -> "#{d.relation_type} (#{d.events.length})")
      .on 'click', (d) ->
        debugger

draw_all_events = (events) ->
  _events = _.chain(events)

  


draw_histogram = ->
  by_date = _all_events.groupBy((d) -> d.date.format('MM/YY')).value()

  months = []
  oldest = _all_events.first().value().date
  newest = _all_events.last().value().date
  while oldest < newest
    months.push oldest.format('MM/YY')
    oldest = oldest.add('months', 1)


  svg = d3.select("#chart")
    .append("svg")
    .attr("width", width)
    .attr("height", height);


  x = d3.scale.ordinal()
    .domain(months)
    .rangeRoundBands([0, width]);

  y = d3.scale.linear()
    .domain([0, _.chain(by_date).map((d) -> d.length).max().value()])
    .range([0, height]);

  svg.selectAll("rect")
      .data(months)
    .enter().append("rect")
      .attr("width", x.rangeBand())
      .attr("x", (d) -> x(d))
      .attr("y", (d) -> height - y((by_date[d] || []).length))
      .attr("height", (d) -> y((by_date[d] || []).length))



