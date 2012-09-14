width = 800
height = 100

window.draw_activity_histogram = (events) ->
  root = d3.select(@).select('svg.activity')

  by_date =  _(events).groupBy((d) -> moment(d.date).format('DD/MM/YY'))

  oldest = moment(_(events).min((e) -> e.date).date)
  newest = moment(_(events).max((e) -> e.date).date)

  days = []
  while oldest < newest
    days.push oldest.format('DD/MM/YY')
    oldest = oldest.add('days', 1)

  if days.length < 5
    root.classed('hidden', true)
  else
    root.classed('hidden', false)

  x = d3.scale.ordinal()
    .domain(days)
    .rangeRoundBands([0, width])

  y = d3.scale.linear()
    .domain([0, _.chain(by_date).map((d) -> d.length).max().value()])
    .range([0, height])

  recs = root
    .selectAll("rect")
    .data(days, (d) -> d)
  recs.enter().append("rect")
    .attr("width", x.rangeBand())
    .attr("x", (d) -> x(d))
    .attr("y", (d) -> height - y((by_date[d] || []).length))
    .attr("height", (d) -> y((by_date[d] || []).length))
  recs.exit().remove()
  recs.transition().duration(500)
    .attr("x", (d) -> x(d))
    .attr("y", (d) -> height - y((by_date[d] || []).length))
    .attr("width", x.rangeBand())
    .attr("height", (d) -> y((by_date[d] || []).length))
