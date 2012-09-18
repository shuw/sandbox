width = 800
height = 100

HTML_TEMPLATE = '
  <div class="activity">
    <svg></svg>
    <div class="legend">
      <div class="labels"></div>
      <div class="description">News Activity Histogram</div>
      <div style="display: none" class="tooltip">&nbsp;</div>
    </div>
  </div>
'

DATE_FORMAT = 'MM/DD/YY'

window.draw_activity_histogram = (events) ->
  $(HTML_TEMPLATE).appendTo(@) if $(@).find('.activity').length == 0
  $el = $(@).find('.activity')
  root = d3.select($el[0])


  by_date =  _(events).groupBy((d) -> moment(d.date).format(DATE_FORMAT))
  oldest = moment(_(events).min((e) -> e.date).date)
  newest = moment(_(events).max((e) -> e.date).date)

  current = oldest.clone()
  days = [current.format(DATE_FORMAT)]
  days.push(current.add('days', 1).format(DATE_FORMAT)) while current < newest

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
      $el.find('.description, .labels').hide()
      $el.find('.tooltip').show()
        .css('left', "#{x}px")
        .text("#{d} (#{by_date[d].length} events)")
    )
    .on('mouseout', (d) ->
      $el.find('.description, .labels').show()
      $el.find('.tooltip').hide()
    )
  recs.exit().remove()
  recs.transition().duration(500).call(update_graph)

  labels = root.select('.labels').selectAll('.label')
    .data([oldest, newest])
  labels.enter().append('div').classed('label', true)
  labels.text((d) -> d.format('MMM Do, YYYY'))