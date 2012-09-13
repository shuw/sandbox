(window.relations ||= {}).political_ad =
  renderable: (political_ad) -> true

  render: (political_ads) ->
    root = d3.select(@)
