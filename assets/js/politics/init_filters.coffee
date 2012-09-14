window.init_filters = (events, on_events_selected) ->
  by_pkey = sort_by_occurrences(events, (d) -> d.params.pkey?.topic_id)
  by_relation_type = sort_by_occurrences(events, (d) -> d.relation_type)

  root = d3.select('#filters')

  root
    .append('div').classed('link all', true)
    .text('All')
    .on('click', -> on_events_selected(events))

  root
    .call(-> @append('h2').text('Relations'))
    .selectAll('.relation')
      .data(by_relation_type)
    .enter()
      .append('div')
      .classed('relation link', true)
        .text((d) -> d[0].relation_type)
        .on('click', on_events_selected)


  root
    .call(-> @append('h2').text('Entities'))
    .selectAll('.entity')
    .data(by_pkey[..20])
  .enter()
    .append('div')
    .classed('entity link', true)
      .text((d) -> d[0].params.pkey.label)
      .on('click', on_events_selected)

  on_events_selected(events)