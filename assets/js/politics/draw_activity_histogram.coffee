width = 800
height = 100

HTML_TEMPLATE = '
  <div class="activity">
    <h1>Activity</h1>
    <svg></svg>
    <div class="legend">
      <div class="labels"></div>
      <div style="display: none" class="tooltip">&nbsp;</div>
    </div>
  </div>
'

window.draw_activity_histogram = (events) ->
  $el = $(@)
  $(HTML_TEMPLATE).appendTo(@) if $el.find('.activity').length == 0
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
    .attr("width", x.rangeBand() - 1)
    .attr("height", (d) -> y((by_date[d] || []).length))

  recs = root.select('svg').selectAll("rect")
    .data(days, (d) -> d)
  recs.enter().append("rect")
    .call(update_graph)
    .on('mouseover', (d) ->
      x = parseInt($(this).attr('x'))
      $el.find('.tooltip').show().text(d).css('left', "#{x}px")
    )
    .on('mouseout', (d) -> $el.find('.tooltip').hide())
  recs.exit().remove()
  recs.transition().duration(500).call(update_graph)

  root.select('.labels').selectAll('.label')
    .data([oldest, newest])
  .enter()
    .append('div').classed('label', true)
    .text((d) -> d.format('MMM Do, YYYY'))