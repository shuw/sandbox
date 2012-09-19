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
# TODO: Limit events per relation
# TODO: sidebar search wheel

# TODO: allows duplicate events in clusters in all view
# TODO: entity filter should search other predicates
# TODO: sort more interesting clusters first in all view
# TODO: rename "news activity histogram" -> "event activity"

# TODO: Speech relation needs more predicates (i.e. location)

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

