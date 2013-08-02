m = [20, 120, 20, 120]
w = 1280 - m[1] - m[3]
h = 800 - m[0] - m[2]
i = 0
root = null

tree = d3.layout.tree().size([h, w])

diagonal = d3.svg.diagonal().projection((d) -> [d.y, d.x] )

vis = d3.select("#root").append("svg:svg")
    .attr("width", w + m[1] + m[3])
    .attr("height", h + m[0] + m[2])
  .append("svg:g")
    .attr("transform", "translate(" + m[3] + "," + m[0] + ")")

d3.json("/data/flare.json", (json) ->
  root = json
  root.x0 = h / 2
  root.y0 = 0

  toggleAll = (d) ->
    if (d.children)
      d.children.forEach(toggleAll)
      toggle(d)

  # Initialize the display to show a few nodes.
  root.children.forEach(toggleAll)
  toggle(root.children[1])
  toggle(root.children[1].children[2])
  toggle(root.children[9])
  # toggle(root.children[9].children[0])

  update(root)
)

update = (source) ->
  duration = d3.event && (if d3.event.altKey then 5000 else 500)

  # Compute the new tree layout.
  nodes = tree.nodes(root).reverse()

  # Normalize for fixed-depth.
  nodes.forEach((d) -> d.y = d.depth * 180 )

  # Update the nodes…
  node = vis.selectAll("g.node")
      .data(nodes, (d) -> d.id || (d.id = ++i) )

  # Enter any new nodes at the parent's previous position.
  nodeEnter = node.enter().append("svg:g")
      .attr("class", "node")
      .attr("transform", (d) -> "translate(" + source.y0 + "," + source.x0 + ")")
      .on("click", (d) -> toggle(d) update(d) )

  nodeEnter.append("svg:circle")
      .attr("r", 1e-6)
      .style("fill", (d) -> if d._children then "lightsteelblue" else "#fff")

  nodeEnter.append("svg:text")
      .attr("x", (d) -> d.children || (if d._children then -10 else 10))
      .attr("dy", ".35em")
      .attr("text-anchor", (d) -> d.children || (if d._children then "end" else "start"))
      .text((d) -> d.name )
      .style("fill-opacity", 1e-6)

  # Transition nodes to their new position.
  nodeUpdate = node.transition()
      .duration(duration)
      .attr("transform", (d) -> "translate(" + d.y + "," + d.x + ")")

  nodeUpdate.select("circle")
      .attr("r", 4.5)
      .style("fill", (d) -> if d._children then "lightsteelblue" else "#fff")

  nodeUpdate.select("text")
      .style("fill-opacity", 1)

  # Transition exiting nodes to the parent's new position.
  nodeExit = node.exit().transition()
      .duration(duration)
      .attr("transform", (d) -> "translate(" + source.y + "," + source.x + ")")
      .remove()

  nodeExit.select("circle")
      .attr("r", 1e-6)

  nodeExit.select("text")
      .style("fill-opacity", 1e-6)

  # Update the links…
  link = vis.selectAll("path.link")
      .data(tree.links(nodes), (d) -> d.target.id )

  # Enter any new links at the parent's previous position.
  link.enter().insert("svg:path", "g")
      .attr("class", "link")
      .attr("d", (d) ->
        o = {x: source.x0, y: source.y0}
        diagonal({source: o, target: o})
      )
    .transition()
      .duration(duration)
      .attr("d", diagonal)

  # Transition links to their new position.
  link.transition()
      .duration(duration)
      .attr("d", diagonal)

  # Transition exiting nodes to the parent's new position.
  link.exit().transition()
      .duration(duration)
      .attr("d", (d) ->
        o = {x: source.x, y: source.y}
        diagonal({source: o, target: o})
      )
      .remove()

  # Stash the old positions for transition.
  nodes.forEach((d) ->
    d.x0 = d.x
    d.y0 = d.y
  )


# Toggle children.
toggle = (d) ->
  if (d.children)
    d._children = d.children
    d.children = null
  else
    d.children = d._children
    d._children = null