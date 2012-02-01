w = 960
h = 500
fill = d3.scale.category20()

vis = d3.select("#chart").append("svg")
   .attr("width", w)
   .attr("height", h)

d3.json "data/celebrities_started_dating.json", (json) ->
  debugger
  


  force = d3.layout.force()
    .charge(-120)
    .linkDistance(30)
    .nodes(json.nodes)
    .links(json.links)
    .size([w, h])
    .start()

  link = vis.selectAll("line.link")
    .data(json.links)
    .enter().append("line")
    .attr("class", "link")
    .style("stroke-width", (d) -> Math.sqrt(d.value))
    .attr("x1", (d) -> d.source.x)
    .attr("y1", (d) -> d.source.y)
    .attr("x2", (d) -> d.target.x)
    .attr("y2", (d) -> d.target.y)

  node = vis.selectAll("circle.node")
    .data(json.nodes)
    .enter().append("circle")
    .attr("class", "node")
    .attr("cx", (d) -> d.x)
    .attr("cy", (d) -> d.y)
    .attr("r", 5)
    .style("fill", (d) -> fill(d.group))
    .call(force.drag)

  node.append("title")
     .text( (d) -> d.name )

  force.on "tick", () ->
    link.attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

  node
    .attr("cx", (d) -> d.x)
    .attr("cy", (d) -> d.y)
