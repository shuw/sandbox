width = 800
height = 100

window.draw_activity_histogram = (events) ->
  root = d3.select(@).select(".activity")

  by_date =  _(events).groupBy((d) -> moment(d.date).format('MM/DD/YY'))
  oldest = moment(_(events).min((e) -> e.date).date)
  newest = moment(_(events).max((e) -> e.date).date)

  current = oldest.clone()
  days = [current.format('DD/MM/YY')]
  days.push(current.add('days', 1).format('MM/DD/YY')) while current < newest

  root.classed('hidden', days.length < 4)

  x = d3.scale.ordinal().domain(days).rangeRoundBands([0, width])
  y = d3.scale.linear().domain([0, _.chain(by_date).map((d) -> d.length).max().value()]).range([0, height])

  update_graph = ->
    @attr("x", (d) -> x(d))
    .attr("y", (d) -> height - y((by_date[d] || []).length))
    .attr("width", x.rangeBand())
    .attr("height", (d) -> y((by_date[d] || []).length))

  recs = root.select('svg').selectAll("rect")
    .data(days, (d) -> d)
  recs.enter().append("rect").call(update_graph)
  recs.exit().remove()
  recs.transition().duration(500).call(update_graph)


  root.select('.labels').selectAll('.label')
    .data([oldest, newest])
  .enter()
    .append('div').classed('label', true)
    .text((d) -> d.format('MMM Do, YYYY'))