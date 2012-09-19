generic_relation =

  css_class_name: 'generic_relation'
  hide_entity_avatar: true

  renderable: (event) ->
    event.params.pkey?

  render: (events) ->
    root = d3.select(@)

    events = _(events).map (e) ->
      _(e.params.pkey).chain().clone().extend(
        {
          news_event_id: e.news_event_id
          headline: e.headline
        }
      ).value()

    root.selectAll('.event')
      .data(events)
    .enter()
      .append('div').classed('event', true)
      .call(create_avatar)
      .append('a').classed('headline', true)
        .attr('href', (d) -> news_event_path(d.news_event_id))
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
