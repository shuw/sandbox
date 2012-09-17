WIDTH = 320
HEIGHT = 240

(window.relations ||= {}).political_ad =
  renderable: (event) -> event.params.pkey? && event.media?

  render: (events) ->
    root = d3.select(@)
    events = _(events).map (e) ->
      _(e.params.pkey).chain().clone().defaults({
        link: e.media.link
      }).value()

    root.selectAll('.ad')
      .data(events)
    .enter()
      .append('div').classed('ad', true)
      .call(avatar_creator)
      .append('a')
        .attr('target', '_blank')
        .attr('href', (d) -> "http://www.youtube.com/v/#{d.link}?autoplay=1")
        .append('img')
        .attr('src', (d) -> "http://img.youtube.com/vi/#{d.link}/0.jpg")