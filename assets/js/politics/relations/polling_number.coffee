(window.relations ||= {}).polling_number =

  hide_entity_avatar: true

  renderable: (event) ->
    event.params.pkey? &&
    (
      event.params.went_up_by_percent? ||
      event.params.went_down_by_percent?
    )

  # TODO: plot polling numbers over time
  render: (events) ->
    events = _(events).map((e) ->
      _(e.params.pkey).chain().clone().defaults(
        news_event_id: e.news_event_id
        date: e.date,
        direction_up: e.params.went_up_by_percent?
        new_percentage: e.params.went_up_by_percent.label || e.went_down_by_percent.label
      ).value()
    )


    groups = _(events).chain()
      .groupBy((e) -> e.topic_id)
      .map((items) ->
        items[0].results = _(items).sortBy((d) -> -d.date)
        items[0]
      )
      .value()

    d3.select(@).selectAll('.results')
      .data(groups)
    .enter()
      .append('div').classed('results', true)
      .call(create_avatar)
      .selectAll('.result')
      .data((d) -> d.results)
    .enter()
      .append('a')
      .attr('href', (d) -> news_event_path(d.news_event_id))
      .classed('result', true)
      .text((d) -> (if d.went_up_by_percent then '▲' else '▼') + d.new_percentage)
