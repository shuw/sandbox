#= require_tree politics
#= require vendor/moment_range

_.mixin(_.string.exports())

window.elections_init = ->
  events = normalize_events(POLITICS_DATA)
  init_filters(events, (selected) ->
    d3.selectAll('#root')
      .data([selected])
      .each(draw_groups)
      .each(draw_raw_data)
  )

