WIDTH = 320
HEIGHT = 240

(window.relations ||= {}).political_ad =
  renderable: (event) -> event.media?

  render: (events) ->
    root = d3.select(@)
    events = _(events).map (e) ->
      {
        link: e.media.link
      }

    root.selectAll('.video')
      .data(events)
    .enter()
      .append('a').classed('video', true)
      .attr('target', '_blank')
      .attr('href', (d) -> "http://www.youtube.com/v/#{d.link}?autoplay=1")
      .append('img')
      .attr('src', (d) -> "http://img.youtube.com/vi/#{d.link}/0.jpg")