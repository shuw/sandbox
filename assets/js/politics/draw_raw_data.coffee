# Draw raw data for exploring

window.draw_raw_data = (events) ->
  events_by_relation = _(events).groupBy((event) -> event.relation_type)
  grouped_events = _(events_by_relation).chain()
    .sortBy((events) -> -events.length)
    .map((events) ->
      {
        events: events,
        param_histogram: _(events).chain()
          .map((e) -> _(e.params).keys())
          .flatten()
          .groupBy((k) -> k)
          .map((l, k) -> { count: l.length, name: k })
          .sortBy('count')
          .value()
      }
    )
    .value()

  relations_sel = d3.select('#raw_headlines')
    .selectAll('.relation')
    .data(grouped_events)
  .enter()
    .append('div')
    .classed('relation', true)
    .call(-> @append('h1').text((d) -> "#{d.events[0].relation_type} (#{d.events.length})"))

  relations_sel.append('ul').selectAll('.param')
    .data((d) -> d.param_histogram)
  .enter()
    .append('li').classed('param', true)
    .text((p) -> "#{p.name} (#{p.count})")

  relations_sel.append('ul').selectAll('.event')
    .data((d) -> d.events)
  .enter()
    .append('li').classed('event', true)
    .text((e) -> "#{e.headline} (#{e.news_event_id})")
