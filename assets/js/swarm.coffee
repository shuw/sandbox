width = $(window).width()
height = $(window).height()

svg = null
_news = null

force = d3.layout.force().links([]).size([width, height])
color = d3.scale.category10()

foci = [{x: 150, y: 150}, {x: 350, y: 250}, {x: 700, y: 400}]

window.swarm_init = (p_data_path, p_test_mode) ->
  svg = d3.select('#root')
    .append('svg:svg')
    .attr('width', width)
    .attr('height', height)

  $.ajax p_data_path, success: got_data
  force.on 'tick', tick


got_data = (news) ->
  _news = _.chain(news).map((d) ->
    {
      id: d.news_event_id
      relation_type: d.relation_type
    })
    .filter((d) -> d.relation_type?)
    .take(10)

  force.nodes(_news.value())
  svg.selectAll('circle.node')
      .data(_news.value())
    .enter().append('circle')
      .classed('node', true)
      .attr("r", 8)
      .style("fill", (d) -> color(d.relation_type))
      .style("stroke", (d) -> d3.rgb(color(d.relation_type)).darker(2))
      .style("stroke-width", 1.5)
      .call(force.drag)

  force.start()


create_news_cell = (d) ->
  debugger


tick = (e) ->
  # Push nodes toward their designated focus.
  # k = .1 * e.alpha

  _news.each (o, i) ->
    # o.y += (foci[o.id].y - o.y) * k
    o.x += 0.3

  svg.selectAll("circle.node").call(update_positions)

update_positions = ->
  @attr("cx", (d) -> d.x)
  @attr("cy", (d) -> d.y)
