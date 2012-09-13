(window.relations ||= {}).criticism =
  renderable: (event) -> event.params.pkey? && event.params.target?

  render: (events) ->
    root = d3.select(@)

    events = _(events).chain().map((d) ->
        _(d.params.pkey).chain().clone().defaults(
          target: d.params.target
          reason: d.params.reason_commonentity?.label
        ).value()
      ).value()

    by_target = sort_by_occurrences(events, ((d) -> d.topic_id), false)
    root.selectAll('.criticism')
      .data(by_target)
    .enter()
      .append('div').classed('criticism', true)
      .each(draw_target_criticized)

draw_target_criticized = (events_grouped) ->
  root = d3.select(@)

  root.append('div').classed('sources', true)
    .selectAll('.source')
      .data(events_grouped)
    .enter()
      .append('div').classed('source', true)
        .call(avatar_creator)
      .append('div').classed('reason', true)
        .text((d) -> d.reason)

  root.selectAll('.target')
    .data([events_grouped[0].target])
  .enter()
    .append('div').classed('target', true)
    .call(avatar_creator)