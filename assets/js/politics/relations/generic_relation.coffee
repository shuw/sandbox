generic_relation =

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


configure_generic_relation = (props) ->
  _(generic_relation).chain().clone().extend(props).value()


_((window.relations ||= {})).extend(
  campaign_rally: configure_generic_relation(
    friendly_name: 'Campaign rallies'
  ),
  campaign_funding: configure_generic_relation(
    friendly_name: 'Campaign funding'
  ),
  party_nomination: configure_generic_relation(
    friendly_name: 'Party Nomination'
  ),
  interviewed: configure_generic_relation(
    friendly_name: 'Interviewed'
  ),
)
