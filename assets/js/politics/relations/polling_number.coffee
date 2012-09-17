(window.relations ||= {}).polling_number =
  renderable: (event) ->
    event.params.pkey? &&
    (
      event.params.went_up_by_percent? ||
      event.params.went_down_by_percent?
    )

  # TODO: Include subpredicate occurred_at_event if exists
  render: (events) ->
    events = _(events).map((e) ->
      _(e.params.pkey).chain().clone().defaults(
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
      .call(avatar_creator)
      .selectAll('.result')
      .data((d) -> d.results)
    .enter()
      .append('div')
      .classed('result', true)
      .text((d) -> (if d.went_up_by_percent then '▲' else '▼') + d.new_percentage)
