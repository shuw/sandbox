MAX_PCT_PER_FRAME:       0.001
UPDATE_INTERVAL:         20

w = 1300
h = 700
fill = d3.scale.category20()

Graph =
  init: ->
    @vis = d3.select("#chart").append("svg")
      .attr("width", w)
      .attr("height", h)

    d3.json "data/celebrities_started_dating.json", (news_events) =>
      @news_events = news_events
      @refresh()

  refresh: ->
    nodeMap = {}
    linksToAdd = _(@news_events).chain().map((news_event) =>
      persons = _(news_event.params).filter (param) ->
        param.name == 'person' || param.name == 'celebrity'

      if persons.length >= 2
        # TODO: Handle > 2 params
        param_nodes = _(news_event.params).map (param) ->
          node = (nodeMap[param.topic_id || "param_#{param.id}"] ||= param)

        return source: param_nodes[0], target: param_nodes[1]
    ).compact().value()

    links = linksToAdd

    nodes = _(nodeMap).values()

    force = d3.layout.force()
      .gravity(.05)
      .distance(100)
      .charge(-100)
      .nodes(nodes)
      .links(links)
      .size([w, h])
      .start()

    link = @vis.selectAll("line.link")
      .data(links)
      .enter().append("line")
      .attr("class", "link")
      .style("stroke-width", (d) -> 2)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    node = @vis.selectAll("g.node")
      .data(nodes)
      .enter().append("svg:g")
      .attr("class", "node")
      .call(force.drag)

    node.append("svg:image")
      .attr("class", "circle")
      .attr("xlink:href", (d) -> d.topic_image || '/images/fb_no_face.gif' )
      .attr("x", "-20px")
      .attr("y", "-30px")
      .attr("width", "40px")
      .attr("height", "60px")

    node.append("title")
      .text((d) -> d.topic_name || d.name)

    force.on "tick", () ->
      link.attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)

      node.attr "transform", (d) -> "translate(#{d.x},#{d.y})"


    # # Precalc
    # debugger
    # firstTimestamp      = moment @news_events[0].date
    # lastTimestamp       = moment _(@news_events).last().date
    # fullDuration        = lastTimestamp - firstTimestamp
    # maxDurationPerFrame = fullDuration * MAX_PCT_PER_FRAME

    # # What we're actually displaying
    # current   = firstTimestamp
    # nextIndex = 0
    # nodes = []
    # links = []


    # refreshData()
    # setInterval (=>
      

    # ), UPDATE_INTERVAL

$ => Graph.init()