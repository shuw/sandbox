width = 960
height = 500
color = d3.scale.category20c()

$ ->
  treemap = d3.layout.treemap()
      .size([width, height])
      .sticky(true)
      .value( (d) -> d.size)

  div = d3.select("#chart").append("div")
      .style("position", "relative")
      .style("width", width + "px")
      .style("height", height + "px")

  d3.json "/data/flare.json", (json) ->
    div.data([json]).selectAll("div")
        .data(treemap.nodes)
      .enter().append("div")
        .attr("class", "cell")
        .style("background", (d) -> if d.children then color(d.name) else null)
        .call(cell)
        .text( (d) -> if d.children then null else d.name )

    d3.select("#size").on "click", ->
      div.selectAll("div")
          .data(treemap.value((d) -> d.size))
        .transition()
          .duration(1500)
          .call(cell)

      d3.select("#size").classed("active", true)
      d3.select("#count").classed("active", false)

    d3.select("#count").on "click", ->
      div.selectAll("div")
          .data(treemap.value((d) -> 1))
        .transition()
          .duration(1500)
          .call(cell)

      d3.select("#size").classed("active", false)
      d3.select("#count").classed("active", true)

  cell = ->
    @style("left", (d) -> d.x + "px" )
    @style("top", (d) -> d.y + "px" )
    @style("width", (d) -> Math.max(0, d.dx - 1) + "px" )
    @style("height", (d) -> Math.max(0, d.dy - 1) + "px" )
