w = 960
h = 500
fill = d3.scale.category20()

$ ->
  vis = d3.select("#chart").append("svg")
     .attr("width", w)
     .attr("height", h)

  d3.json "data/celebrities_started_dating.json", (news_events) ->
    nodeMap = {}
    links = _(news_events).chain().first(2).map((news_event) ->
      if news_event.params.length >= 2
        # TODO: Handle > 2 params
        param_nodes = _(news_event.params).map (param) ->
          node = (nodeMap[param.topic_id || "param_#{param.id}"] ||= param)

        return source: param_nodes[0], target: param_nodes[1]
    ).compact().value()

    nodes = _(nodeMap).values()

    debugger
    force = d3.layout.force()
      .linkDistance(30)
      .nodes(nodes)
      .links(links)
      .size([w, h])
      .start()

    link = vis.selectAll("line.link")
      .data(links)
      .enter().append("line")
      .attr("class", "link")
      .style("stroke-width", (d) -> 5)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    node = vis.selectAll("circle.node")
      .data(nodes)
      .enter().append("circle")
      .attr("class", "node")
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
      .attr("r", 5)
      .style("fill", (d) -> fill(d.group))
      .call(force.drag)

    force.on "tick", () ->
      link.attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)

    node
      .attr("cx", (d) -> d.x)
      .attr("cy", (d) -> d.y)
