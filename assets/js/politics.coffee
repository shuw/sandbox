#= require_tree politics

_.mixin(_.string.exports())


# TODO: Create renderer for these relations
# person_raised_campaign_funding
# person_holds_fundraiser
# person_won_party_nomination
# person_interviewed
# person_arrived_in


# TODO: Fast Preview on hover
# TODO: Arrows and affiliation border in criticisms graph viz
# TODO: Polling numbers as graph
# TODO: Limit size of feed for perf reasons

window.politics_init = ->
  events = normalize_events(POLITICS_DATA)
  init_filters(events, (selected) ->
    d3.selectAll('#root')
      .data([selected])
      .each(draw_activity_histogram)
      .each(draw_groups)
      # .each(draw_raw_data)
  )
  $('#root').removeClass('hidden')

