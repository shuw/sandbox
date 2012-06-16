width = $(window).width()
height = $(window).height()

center_x = Math.floor width / 2
center_y = Math.floor height / 2

svg = null

_nodes = _.chain([])
_leaders = _.chain([])

force = d3.layout.force()
  .links([])
  .size([width, height])
  .linkStrength(0.1)
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
  # filter to news with relation types
  _nodes = _.chain(news).map((d) ->
    {
      id: d.news_event_id
      relation_type: d.relation_type
    })

  # elect leaders for each news group
  _groups = _nodes.groupBy('relation_type')

  _leaders = _groups.map((nodes, relation_type) -> nodes[0])
  _links = _groups.map((nodes, relation_type) ->
      _(nodes).map (d) ->
        {
          source: d,
          target: nodes[0]
        }
    )
    .flatten()

  debugger
  force.nodes(_nodes.value()).links(_links.value())

  svg.selectAll('circle.node')
      .data(_nodes.value())
    .enter().append('circle')
      .classed('node', true)
      .attr("r", 8)
      .style("fill", (d) -> color(d.relation_type))
      .style("stroke", (d) -> d3.rgb(color(d.relation_type)).darker(2))
      .style("stroke-width", 1.5)
      .call(force.drag)

  force.start()


tick = (e) ->
  # Push nodes toward their designated focus.
  # k = .1 * e.alpha

  _leaders.each (d) ->
    d.direction ||= (Math.PI * 2) * Math.random()
    d.turn_left = Math.random() > 0.5

    d.x += Math.sin(d.direction) * 1
    d.y += Math.cos(d.direction) * 1

    from_center = Math.sqrt Math.pow(d.x - center_x, 2) + Math.pow(d.y - center_y, 2)

    d.direction += (from_center / width) * 2 * (if d.turn_left then -1 else 1)

  svg.selectAll("circle.node").call(update_positions)

  force.resume()

update_positions = ->
  @attr("cx", (d) -> d.x)
  @attr("cy", (d) -> d.y)
