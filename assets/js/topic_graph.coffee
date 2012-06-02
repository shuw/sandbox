MAX_PCT_PER_FRAME =       0.001
UPDATE_INTERVAL =         1000

w = 1300
h = 700
fill = d3.scale.category20()

# TODO: Visualize breakups as well
# - make people with more connections bigger
# - add keyboard highlighting
window.TopicGraph =
  init: (data_path) ->
    @nodeMap = {}
    @nodes   = []
    @links   = []

    @vis = d3.select("#chart").append("svg")
      .attr("width", w)
      .attr("height", h)

    # TODO: Order events by date
    d3.json "data/#{data_path}.json", (news_events) =>
      @news_events = news_events
      @start()

  processData: (news_events)->
    _(news_events).chain().map((news_event) =>
      persons = _(news_event.params).filter (param) ->
        return true if param.name == 'person' || param.name == 'celebrity'
        return true if param.name == 'org1'|| param.name == 'org2'
        return false

      if persons.length >= 2
        # TODO: Handle > 2 params
        param_nodes = _(news_event.params).map (param) =>
          key = param.topic_id || "param_#{param.id}"
          node = @nodeMap[key]
          unless node
            node = @nodeMap[key] = param

            @nodes.push param
          node

        @links.push source: param_nodes[0], target: param_nodes[1]

    ).compact().value()

  start: ->
    #  # Precalc
    # firstTimestamp      = moment @news_events[0].date
    # lastTimestamp       = moment _(@news_events).last().date
    # fullDuration        = lastTimestamp - firstTimestamp
    # maxDurationPerFrame = fullDuration * MAX_PCT_PER_FRAME

    # # What we're actually displaying
    # current   = firstTimestamp

    @layout = d3.layout.force()
      .gravity(.05)
      .distance(80)
      .charge(-100)
      .size([w, h])

    @refreshData()
    setInterval (=>
      @processData(@news_events.splice(0, 5))
      @refreshData()
    ), 500

  refreshData: ->
    @layout
      .nodes(@nodes)
      .links(@links)
      .start()
      .on "tick", => @updateFrame()

    @node = @vis.selectAll("g.node").data(@nodes)
    @node
      .append("title")
      .text((d) -> d.topic_name || d.name)
    @node.enter()
      .append("svg:g")
      .attr("class", "node")
      .call(@layout.drag)
      .append("svg:image")
      .attr("class", "circle")
      .attr("xlink:href", (d) -> d.topic_image || '/images/fb_no_face.gif' )
      .attr("x", "-20px")
      .attr("y", "-30px")
      .attr("width", "40px")
      .attr("height", "60px")
    @node.exit()
      .remove()

    @link = @vis.selectAll("line.link").data(@links)
    @link.enter().append("line")
      .attr("class", "link")
      .style("stroke-width", (d) -> 2)
      .attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)
    @link.exit().remove()

  updateFrame: ->
    @link.attr("x1", (d) -> d.source.x)
      .attr("y1", (d) -> d.source.y)
      .attr("x2", (d) -> d.target.x)
      .attr("y2", (d) -> d.target.y)

    @node.attr "transform", (d) -> "translate(#{d.x},#{d.y})"