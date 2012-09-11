MIN_GROUP_THRESHOLD = 5

window.draw_groups = (events) ->
  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  consume_group = (param_key) ->
    return _(events_by_id).chain()
      .values()
      .groupBy((e) -> e.params[param_key]?.topic_id)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length > MIN_GROUP_THRESHOLD
          events = _(events).sortBy (e) -> -e.date

          unique_id = ''
          # delete events from maste rlist so they are consumed
          _(events).each (e) ->
            delete events_by_id[e.news_event_id]
            unique_id += e.news_event_id

          {
            date: events[0].date
            param: events[0].params[param_key]
            events: events
            unique_id: unique_id
          }
      ).compact().sortBy((d) -> -d.events.length).value()

  groups = _.union consume_group('for_event'),consume_group('pkey')

  sel = d3.select(@).selectAll('.group')
    .data(groups, (d) -> d.unique_id)
  sel.enter()
    .append('div').classed('group', true)
    .call(-> @append('h1').text((d) -> d.param.topic.name))
    .each(draw_group)
  sel.exit().remove()


draw_group = (group) ->
  relation_groups = _(group.events).chain()
    .groupBy((event) -> event.relation_type)
    .map((events, relation_type) ->
      switch relation_type
        # TODO:
        #   for some relations consider rejecting
        #   events without affiliation x.reject((e) -> e.affiliations.length == 0)

        # TODO: relations to handle
        # person_has_polling_numbers
        # person_gave_a_speech
        # person_holds_campaign_rally
        # person_raised_campaign_funding
        # person_holds_fundraiser
        # person_runs_political_ad
        # organization_runs_political_ad
        # person_won_party_nomination
        # person_criticized_person
        when 'person_gave_a_speech'
          draw_function = draw_speeches
        else console.log("Don't know how to draw #{relation_type}")

      if draw_function
        {
          relation_type: relation_type
          events: events
          draw_function: draw_function
        }
    )
    .compact()
    .sortBy((d) -> -d.events.length)
    .value()

  d3.select(@).selectAll('.relation')
    .data(relation_groups)
  .enter()
    .append('div')
      .attr('class', (d) -> d.relation_type)
      .classed('relation', true)
      .call(-> @append('h2').text((d) -> d.relation_type))
      .each((d) -> d.draw_function.call(@, d.events))


