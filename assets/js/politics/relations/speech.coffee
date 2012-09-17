(window.relations ||= {}).speech =

  friendly_name: 'Speeches'

  renderable: (event) -> event.params.pkey?

  render: (events) ->
    root = d3.select(@)

    # Normalized events
    events = _(events)
      .map((event) ->
        _(event.params.pkey).chain().clone().defaults(
          affiliation: event.params.pkey.affiliation
          quote: event.params.quote_commonentity?.label
        ).value()
      )

    top_speakers = sort_by_occurrences(events, ((d) -> d.label), true)

    summary = root.append('div').classed('summary', true)
    summary.selectAll('.speaker')
      .data(top_speakers[..4])
    .enter()
      .append('a')
      .classed('speaker', true)
      .call(avatar_creator)
    prefix = (if top_speakers.length > 5 then "and #{top_speakers.length - 5} others " else "")
    summary.append('span').text("#{prefix}gave a speech")


    quotes = _(events).filter((d) -> d.quote?)
    root.selectAll('.quote')
      .data(quotes)
    .enter()
      .append('div').classed('quote', true)
      .call(avatar_creator)
      .append('span')
        .text((d) -> d.quote)
