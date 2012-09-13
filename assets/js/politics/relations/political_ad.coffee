(window.relations ||= {}).political_ad =
  renderable: (event) -> event.media?

  render: (events) ->
    root = d3.select(@)
    debugger
