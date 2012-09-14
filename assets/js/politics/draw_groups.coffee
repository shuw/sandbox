window.draw_groups = (events) ->
  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  # try to create more interesting clusters first
  create_clusters = ->
    _.union(
      cluster(5, (e) -> e.params.for_event?.label),
      cluster(3, (e) -> e.params.pkey?.label),
      cluster(10, ((e) -> e.relation_type), ((e) -> e.relation_name)),
      cluster(0, (e) -> e.params.pkey?.label),
    )

  cluster = (min_cluster_size, key_func, name_func) ->
    return _(events_by_id).chain()
      .values()
      .groupBy(key_func)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length > min_cluster_size
          events = _(events).sortBy (e) -> -e.date

          unique_id = ''
          # delete events from maste rlist so they are consumed
          _(events).each (e) ->
            delete events_by_id[e.news_event_id]
            unique_id += e.news_event_id

          {
            date: events[0].date
            label: (name_func || key_func)(events[0])
            events: events
            unique_id: unique_id
          }
      ).compact().sortBy((d) -> -d.events.length).value()

  groups = create_clusters()

  sel = d3.select(@).selectAll('.group')
    .data(groups, (d) -> d.unique_id)
  sel.enter()
    .append('div').classed('group', true)
    .call(->
      @append('h1').text((d) -> d.label)
      @append('time').text((d) ->
        end = moment(d.events[Math.floor(d.events.length * 0.05)].date)
        start = moment(d.events[Math.ceil((d.events.length - 1) * 0.95)].date)

        if start.format('dddd M/D') != end
          "#{start.format('M/D')} - #{end.format('dddd M/D')}"
        else
          start.format('dddd M/D')
      )
    )
    .each(draw_group)
  sel.exit().remove()


RELATION_SORT_ORDER = {
  'political_ad' : 1
  'criticism' : 1002
  'speech': 1003
}

draw_group = (group) ->
  relation_groups = _(group.events).chain()
    .groupBy((event) -> event.relation_type)
    .map((events, relation_type) ->
      # TODO:
      #   for some relations consider rejecting
      #   events without affiliation x.reject((e) -> e.affiliations.length == 0)

      # TODO: relations to handle
      # political_ad (need media field of news_data)
      # person_has_polling_numbers
      # person_gave_a_speech
      # person_holds_campaign_rally
      # person_raised_campaign_funding
      # person_holds_fundraiser
      # person_won_party_nomination
      # person_criticized_person
      # person_interviewed
      # person_arrived_in


      if relation = window.relations[relation_type]
        {
          relation_name: events[0].relation_name
          relation_type: events[0].relation_type
          events: events
          render: relation.render
        }
    )
    .compact()
    .sortBy((d) -> RELATION_SORT_ORDER[d.relation_type] || 100000)
    .value()

  d3.select(@).selectAll('.relation')
    .data(relation_groups)
  .enter()
    .append('div')
      .attr('class', (d) -> d.relation_type)
      .classed('relation', true)
      .call(->
        @append('h2').text((d) -> d.relation_name)
      )
      .each((d) -> d.render.call(@, d.events))


