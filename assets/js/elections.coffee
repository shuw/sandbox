#= require_tree politics

_.mixin(_.string.exports())

window.elections_init = ->
  events = normalize_events(POLITICS_DATA)
  init_filters(events, (selected) ->
    d3.selectAll('#root')
      .data([selected])
      .each(draw_activity_histogram)
      .each(draw_groups)
      .each(draw_raw_data)
  )

