window.render_speech = (speeches) ->
  root = d3.select(@)

  # Normalized speeches
  speeches = _(speeches).chain()
    .map((e) ->
      return unless e.params.pkey?
      _(e.params.pkey).chain().clone().defaults(
        affiliation: e.params.pkey.affiliation
        quote: e.params.quote_commonentity?.label
      ).value()
    )
    .compact().value()

  top_speakers = sort_by_occurrences(speeches, ((d) -> d.label), true)
  root.selectAll('.speaker')
    .data(top_speakers[..4])
  .enter()
    .append('a')
    .classed('speaker', true)
    .call(avatar_creator)

  prefix = (if top_speakers.length > 5 then "and #{top_speakers.length - 5} others " else "")
  root.append('span').text("#{prefix}gave a speech")


  quotes = _(speeches).filter((d) -> d.quote?)
  root.selectAll('.quote')
    .data(quotes)
  .enter()
    .append('div').classed('quote', true)
    .call(avatar_creator)
    .append('span')
      .text((d) -> d.quote)
