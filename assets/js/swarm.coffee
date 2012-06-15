width: 800
height: 800
svg = null

layout = d3.layout.force()
  .links([])
  .layout([width, height])
  .start()


window.swarm_init = (p_data_path, p_test_mode) ->
  svg = d3.select('#root')
    .append('svg:svg')
    .attr('width', 800)
    .attr('height', 800)

  $.ajax p_data_path, success: got_data


got_data = (news) ->
  _news = _(news)

  svg.selectAll('svg:circle')
    .data(_news.nodes(_news.value()))
    .enter()
      .append('circle')
      .call(create_news_cell)



create_news_cell = (d) ->
  debugger