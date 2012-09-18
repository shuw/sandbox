(window.relations ||= {}).campaign_rally =

  friendly_name: 'Campaign rallies'

  renderable: (event) ->
    event.params.pkey?

  render: (events) ->
    root = d3.select(@)

    events = _(events).map (e) ->
      _(e.params.pkey).chain().clone().extend(
        {
          headline: e.headline
        }
      ).value()

    root.selectAll('.rally')
      .data(events)
    .enter()
      .append('div').classed('rally', true)
      .call(create_avatar)
      .append('span')
        .text((d) -> d.headline)
