#= require_tree politics

_.mixin(_.string.exports())


# TODO: Create renderer for these relations
# person_has_polling_numbers
# person_holds_campaign_rally
# person_raised_campaign_funding
# person_holds_fundraiser
# person_won_party_nomination
# person_interviewed
# person_arrived_in

window.politics_init = ->
  events = normalize_events(POLITICS_DATA)
  init_filters(events, (selected) ->
    d3.selectAll('#root')
      .data([selected])
      .each(draw_activity_histogram)
      .each(draw_groups)
      .each(draw_raw_data)
  )
  $('#root').removeClass('hidden')

