window.init_filters = (events, on_events_selected) ->
  by_pkey = sort_by_occurrences(events, ((d) -> d.params.pkey?.topic_id))

  root = d3.select('#filters')

  root
    .append('div').classed('link all', true)
    .text('All')
    .on('click', -> on_events_selected(events))

  root.selectAll('.entity')
    .data(by_pkey[..20])
  .enter()
    .append('div')
    .classed('entity', true)
      .append('div').classed('link', true)
      .text((d) -> d[0].params.pkey.label)
      .on('click', on_events_selected)

  on_events_selected(events)