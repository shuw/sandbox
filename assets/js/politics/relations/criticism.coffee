(window.relations ||= {}).criticism =

  renderable: (event) ->
    event.params.pkey? && event.params.target? && event.params.reason_commonentity?

  render: (events) ->
    root = d3.select(@)

    items = _(events).chain().map((d) ->
      for_event = d.params.for_event?.label

      reason = "for #{d.params.reason_commonentity.label}"
      reason += " at #{for_event}" if for_event
      reason += " because #{d.params.quote_commonentity.label}" if d.params.quote_commonentity?



      _(d.params.pkey).chain().clone().defaults(
        news_event_id: d.news_event_id
        target: d.params.target
        reason: reason
        headline: "#{d.params.pkey.topic?.name} criticized #{d.params.target.topic?.name} #{reason}"
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
    .gravity(.05)
    .distance(100)
    .charge(-150)
    .size([width, (items.length / 10) * 100])

  layout
    .nodes(nodes)
    .links(links)
    .on("tick", ->
      link.attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)

      arrows.attr('transform', (d) ->
        x = (d.source.x + d.target.x) / 2
        y = (d.source.y + d.target.y) / 2

        angle = Math.atan2(d.target.y - d.source.y, d.target.x - d.source.x)

        "translate(#{x}, #{y})" + " rotate(#{angle * 180 / Math.PI})"
      )
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

  _(nodes).each (node) ->
    w = Math.floor(node.avatar_image.size[0] * Math.sqrt(node.weight) * 0.5)
    h = Math.floor(node.avatar_image.size[1] * Math.sqrt(node.weight) * 0.5)
    _(node).extend({
      offset_x: -(w / 2)
      offset_y: -(h / 2)
      width: w
      height: h
    })

  link = vis.selectAll("line.link").data(links)
  link.enter().append("line")
    .attr("class", "link")
    .style("stroke-width", (d) -> 2)
  link.exit().remove()

  arrows = vis.selectAll("polygon.arrow").data(links)
  arrows.enter().append('svg:polygon')
    .classed('arrow', true)
    .attr('r', 2)
    .attr('points', (d) -> "0,0 -14,7 -14,-7")
    .on('click', (d) -> open(news_event_path(d.source.news_event_id)))
    .append('title').text((d) -> d.source.headline)
  arrows.exit().remove()

  node = vis.selectAll("g.node").data(nodes)
  node.append("title").text((d) -> d.topic_name || d.name)
  node.enter()
    .append("svg:g")
    .attr("class", "node")
    .call(layout.drag)
    .call(->
      @append("svg:image")
        .attr("xlink:href", (d) -> d.avatar_image.url)
        .attr("x", (d) -> d.offset_x)
        .attr("y", (d) -> d.offset_y)
        .attr("width", (d) -> d.width)
        .attr("height", (d) -> d.height)
      @append('svg:rect')
        .attr('class', (d) -> "#{d.affiliation} avatar")
        .attr("x", (d) -> d.offset_x)
        .attr("y", (d) -> d.offset_y)
        .attr("width", (d) -> d.width)
        .attr("height", (d) -> d.height)
        .on('click', (d) -> open(topic_path(d.topic_id)))
        .append('title').text((d) -> d.label)
    )

  node.exit().remove()


draw_target_criticized = (group) ->
  root = d3.select(@)

  root.append('div').classed('sources', true)
    .selectAll('.source')
      .data(group.items)
    .enter()
      .append('div').classed('source', true)
        .call(create_avatar)
        .call(-> @append('span').classed('arrow', true).text('▶'))
        .append('a').classed('reason', true)
          .attr('href', (d) -> news_event_path(d.news_event_id))
          .text((d) -> d.reason)

  root.selectAll('.target')
    .data([group.items[0].target])
  .enter()
    .append('span').classed('target', true)
    .call(create_avatar)
