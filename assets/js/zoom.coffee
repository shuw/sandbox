_.mixin(_.string.exports())

g_units = null

window.zoomInit = (data_path) ->
  $.ajax data_path, success: (units) ->
    g_units = units
    start()

start = ->
  units = d3.select('#root')
    .selectAll('.unit')
    .data(g_units, (u) -> u.unique_id)
  units.enter()
    .append('div')
    .classed('unit', true)
    .call(-> @each (unit) -> drawUnit(@, unit))
  units.exit().remove()


drawUnit = (el, unit) ->
  switch (unit.unit_type)
    when 'ADD_SINGLE_PHOTO'
      $('<img>')
        .attr(
          'src': unit.images[0].uri
          'width': 200
        )
        .appendTo(el)

      $('<div>')
        .text(unit.score)
        .appendTo(el)

  
