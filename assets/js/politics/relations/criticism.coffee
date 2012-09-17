(window.relations ||= {}).criticism =
  renderable: (event) ->
    event.params.pkey? && event.params.target? && event.params.reason_commonentity?

  # TODO: Include subpredicate occurred_at_event if exists
  render: (events) ->
    root = d3.select(@)

    items = _(events).chain().map((d) ->
        reason = d.params.reason_commonentity.label
        for_event = d.params.for_event?.label
        reason += " at #{for_event}" if for_event

        _(d.params.pkey).chain().clone().defaults(
          target: d.params.target
          reason: reason
        ).value()
      ).value()

    render_graph.call(@, items) if items.length > 10

    by_target = sort_by_occurrences(items, ((d) -> d.topic_id))
    root.selectAll('.criticism')
      .data(by_target)
    .enter()
      .append('div').classed('criticism', true)
      .each(draw_target_criticized)


width = 800
node_width = 20
node_height = Math.floor(node_width * 3.0 / 2.0)
render_graph = (items) ->
  nodes = {}
  links = []
  _(items).each (item) ->
    source = nodes[item.topic_id] ||= item
    target = nodes[item.target.topic_id] ||= item.target
    links.push(source: source, target: target)

  height = Math.pow(items.length, 0.6) * 60

  nodes = _(nodes).values()

  layout = d3.layout.force()
    .gravity(.03)
    .distance(100)
    .charge(-100)
    .size([width, (items.length / 10) * 100])

  layout
    .nodes(nodes)
    .links(links)
    .on("tick", ->
      link.attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)
      node.attr("transform", (d) ->
        r = 40 * Math.sqrt(d.weight)
        d.x = Math.max(r, Math.min(width - r, d.x));
        d.y = Math.max(r, Math.min(height - r, d.y))
        "translate(#{d.x},#{d.y})"
      )
    )

  vis = d3.select(@).append('svg').classed('graph', true)
    .attr('height', "#{height}px")
    .attr('width', "#{width}px")

  layout.start().alpha(0.05)

  link = vis.selectAll("line.link").data(links)
  link.enter().append("line")
    .attr("class", "link")
    .style("stroke-width", (d) -> 2)

  node = vis.selectAll("g.node").data(nodes)
  node.append("title").text((d) -> d.topic_name || d.name)
  node.enter()
    .append("svg:g")
    .attr("class", "node")
    .call(layout.drag)
    .append("svg:image")
    .attr("class", "circle")
    .attr("xlink:href", (d) -> d.topic_images?[0]?.sizes[0]?.url || '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png' )
    .attr("x", (d) -> "-#{node_width / 2 * Math.sqrt(d.weight)}px")
    .attr("y", (d) -> "-#{node_height / 2 * Math.sqrt(d.weight)}px")
    .attr("width", (d) -> "#{node_width * Math.sqrt(d.weight)}px")
    .attr("height", (d) -> "#{node_height * Math.sqrt(d.weight)}px")
  node.exit().remove()

  link.exit().remove()


draw_target_criticized = (group) ->
  root = d3.select(@)

  root.append('div').classed('sources', true)
    .selectAll('.source')
      .data(group.items)
    .enter()
      .append('div').classed('source', true)
        .call(avatar_creator)
      .append('div').classed('reason', true)
        .text((d) -> d.reason)

  root.selectAll('.target')
    .data([group.items[0].target])
  .enter()
    .append('div').classed('target', true)
    .call(avatar_creator)