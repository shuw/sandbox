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
      .append('div').classed('video', true)
      .html((d) ->
        "<iframe class=\"youtube-player\" type=\"text/html\" width=\"#{WIDTH}\" height=\"#{HEIGHT}\" src=\"http://www.youtube.com/embed/#{d.link}\" frameborder=\"0\">
        </iframe>"
      )
