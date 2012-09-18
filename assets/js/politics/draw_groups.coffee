RELATION_SORT_ORDER = [
  'political_ad'
  'criticism'
  'speech'
]

HTML_TEMPLATE = '
  <div class="events">
  </div>
'
window.draw_groups = (events) ->
  $(HTML_TEMPLATE).appendTo(@) if $(@).find('.events').length == 0
  root = d3.select(@).select(".events")

  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  # try to create more interesting clusters first
  create_clusters = ->
    _.union(
      cluster_param(2, 'for_event'),
      cluster_param(2, 'pkey'),
      cluster(5,
        ((e) -> e.relation_type),
        ((e) -> e.relation_name)
      ),
      cluster_param(1, 'pkey'),
    )

  cluster_param = (min_cluster_size, param_name) ->
    cluster(min_cluster_size,
      (d) -> d.params[param_name]?.topic_id,
      (d) -> d.params[param_name]?.topic?.name,
      (d) -> d.params[param_name],
    )

  cluster = (min_cluster_size, key_func, name_func, entity_func) ->
    return _(events_by_id).chain()
      .values()
      .groupBy(key_func)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length >= min_cluster_size
          events = _(events).sortBy (e) -> -e.date

          unique_id = ''
          # delete events from maste rlist so they are consumed
          _(events).each (e) ->
            delete events_by_id[e.news_event_id]
            unique_id += e.news_event_id


          {
            entity: entity_func?(events[0])
            date: events[0].date
            label: (name_func || key_func)(events[0])
            events: events
            unique_id: unique_id
          }
      ).compact().sortBy((d) -> -d.events.length).value()

  groups = _(create_clusters()).sortBy((d) -> -d.events[0].date)

  sel = root.selectAll('.group')
    .data(groups, (d) -> d.unique_id)
  sel.enter()
    .append('div').classed('group', true)
    .each((d) ->
      h2 = d3.select(@).append('h2')
      h2.datum(d.entity).call(create_avatar) if d.entity
      h2.append('span').text(d.label)

      draw_group.call(this, d)
    )
    .each(draw_group)
  sel.exit().remove()
  sel.order()



draw_group = (group) ->
  relation_groups = _(group.events).chain()
    .groupBy((event) -> event.relation_type)
    .map((events, relation_type) ->
      # TODO:
      #   for some relations consider rejecting
      #   events without affiliation x.reject((e) -> e.affiliations.length == 0)
      if relation = window.relations[relation_type]
        {
          relation_name: events[0].relation_name
          relation_type: events[0].relation_type
          events: events
          relation: relation
        }
    )
    .compact()
    .sortBy((d) -> RELATION_SORT_ORDER.indexOf(d.relation_type))
    .value()

  d3.select(@).selectAll('.relation')
    .data(relation_groups)
  .enter()
    .append('div')
      .attr('class', (d) -> d.relation_type)
      .classed('relation', true)
      .call(->
        @append('time').text((d) ->
          end = moment(d.events[0].date)
          start = moment(d.events[d.events.length - 1].date)

          if start.format('dddd M/D') != end
            "#{start.format('M/D')} - #{end.format('dddd M/D')}"
          else
            start.format('dddd M/D')
        )
        @append('h3').text((d) -> d.relation_name)
      )
      .each((d) ->
        d.relation.render.call(@, d.events, group.entity)
        if group.entity && d.relation.hide_entity_avatar
          # hide avatar if it's the same as the group entity avatar
          $(@).find(".avatar[topic-id=\"#{group.entity.topic_id}\"]").hide()
      )


