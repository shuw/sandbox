CHART_WIDTH = 200

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
      new_percentage = e.params.went_up_by_percent.label || e.went_down_by_percent.label
      if n = parseInt(new_percentage.split('%')[0])
        fraction = n / 100

      _(e.params.pkey).chain().clone().defaults(
        in_location: e.params.in_location?.topic?.name
        by_organization: e.params.by_organization?.topic?.name
        news_event_id: e.news_event_id
        date: e.date,
        direction_up: e.params.went_up_by_percent?
        new_percentage: new_percentage
        fraction: fraction
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
      .call(->
        @append('span').text((d) -> if d.went_up_by_percent then '▲' else '▼')
        @append('div')
          .classed('bar', true)
          .style('width', (d) -> "#{CHART_WIDTH}px")
          .append('div')
            .classed('fill', true)
            .html('&nbsp;')
            .style('width', (d) -> "#{CHART_WIDTH * d.fraction}px")

        @append('div').classed('description', true)
          .append('span').text((d) -> "#{d.new_percentage}")
          .append('span').text((d) -> if d.in_location then " in #{d.in_location}" else '')
          .append('span').text((d) -> if d.by_organization then " by #{d.by_organization}" else '')
          .append('span').text((d) -> if d.date then " on #{moment(d.date).format('MM/DD/YY')}" else '')
      )
