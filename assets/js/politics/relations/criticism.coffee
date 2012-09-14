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


# TODO: render directed graph
render_graph = (items) ->
  nodes = {}
  links = []
  _(items).each (item) ->
    source = nodes[item.topic_id] ||= item
    target = nodes[item.target.topic_id] ||= item.target
    links.push(
      source: source
      target: target
    )

  height = Math.sqrt(items.length / 10) * 300
  width = 800

  nodes = _(nodes).values()

  layout = d3.layout.force()
    .gravity(.05)
    .distance(80)
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
      node.attr "transform", (d) -> "translate(#{d.x},#{d.y})"
    )

  vis = d3.select(@).append('svg').classed('graph', true)
    .attr('height', "#{height}px")
    .attr('width', "#{width}px")

  layout.start()

  node = vis.selectAll("g.node").data(nodes)
  node
    .append("title")
    .text((d) -> d.topic_name || d.name)
  node.enter()
    .append("svg:g")
    .attr("class", "node")
    .call(layout.drag)
    .append("svg:image")
    .attr("class", "circle")
    .attr("xlink:href", (d) -> d.topic_images?[0]?.sizes[0]?.url || '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png' )
    .attr("x", (d) -> "-#{10 * Math.sqrt(d.weight)}px")
    .attr("y", (d) -> "-#{15 * Math.sqrt(d.weight)}px")
    .attr("width", (d) -> "#{20 * Math.sqrt(d.weight)}px")
    .attr("height", (d) -> "#{30 * Math.sqrt(d.weight)}px")
  node.exit()
    .remove()

  link = vis.selectAll("line.link").data(links)
  link.enter().append("line")
    .attr("class", "link")
    .style("stroke-width", (d) -> 2)
    .attr("x1", (d) -> d.source.x)
    .attr("y1", (d) -> d.source.y)
    .attr("x2", (d) -> d.target.x)
    .attr("y2", (d) -> d.target.y)
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