window.draw_speeches = (speeches) ->
  root = d3.select(@).classed('speeches', true)

  # Normalized speeches
  speeches = _(speeches).chain()
    .map((e) ->
      return unless e.params.pkey?
      speaker = e.params.pkey
      gimage = speaker.topic_images?[0]

      {
        affiliation: speaker.affiliation
        name: speaker.label
        quote: e.params.quote_commonentity?.label
        image: gimage && get_image(gimage, 40, 40) || {
          url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png'
          size: [40, 40]
        }
      }
    )
    .compact().value()

  top_speakers = sort_by_occurrences(speeches, (d) -> d.name)
  root.selectAll('.speaker')
    .data(top_speakers[..4])
  .enter()
    .append('a')
    .classed('speaker', true)
    .call(avatar_creator())

  prefix = (if top_speakers.length > 5 then "and #{top_speakers.length - 5} others " else "")
  root.append('span').text("#{prefix}gave a speech")


  quotes = _(speeches).filter((d) -> d.quote?)
  root.selectAll('.quote')
    .data(quotes)
  .enter()
    .append('div').classed('quote', true)
    .call(avatar_creator())
    .append('span')
      .text((d) -> d.quote)
