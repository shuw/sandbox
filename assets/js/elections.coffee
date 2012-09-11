#= require_tree politics
_.mixin(_.string.exports())

# Filter summaries and these relations because we don't handle them well yet...
FILTERED_RELATIONS = _([
  'source_published_article_about_subjects',
  'author_wrote_article_about_subjects',
  'author_from_source_wrote_article_about_subjects',
  'authors_wrote_articles_about_subject',
  'summary',
]).groupBy((k) -> k)

NORMALIZE_PARAMS = {
  'occurred_at_event': 'for_event'
}

window.elections_init = ->
  # Normalize events and reverse sort by date
  events = _(POLITICS_DATA).chain()
    .reject((e) -> FILTERED_RELATIONS[e.relation_type]?)
    .map((e) ->
      e.date = new Date(e.date)

      _(e.params).each (params, key) ->
        if new_key = NORMALIZE_PARAMS[key]
          e.params[new_key] = params
          delete e.params[key]

      e.relation_type = NORMALIZE_PARAMS[e.relation_type] || e.relation_type
      e
    )
    .sortBy((e) -> -e.date)
    .value()


  d3.selectAll('#root')
    .data([events])
    .each(draw_groups)
    .each(draw_raw_data)


MIN_GROUP_THRESHOLD = 5
draw_groups = (events) ->
  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  consume_group = (param_key) ->
    return _(events_by_id).chain()
      .values()
      .groupBy((e) -> e.params[param_key]?[0]?.topic_id)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length > MIN_GROUP_THRESHOLD
          # delete events from maste rlist so they are consumed
          _(events).each (e) -> delete events_by_id[e.news_event_id]
          {
            date: events[0].date
            param: events[0].params[param_key][0],
            events: events
          }
      ).compact().sortBy((d) -> -d.events.length).value()

  groups = _.union consume_group('for_event'),consume_group('pkey')
  d3.select('#root')
    .selectAll('.event_group')
    .data(groups)
  .enter()
    .append('div').classed('event_group', true)
    .call(-> @append('h1').text((d) -> d.param.topic.name))
    .each(draw_group)



draw_group = (group) ->
  by_relation = _(group.events).groupBy((event) -> event.relation_type)


  # @sleact

  speeches = by_relation['person_gave_a_speech']
  quotes = _(speeches).chain()
    .map((d) -> d.params.quote_commonentity).compact()
    .value()

draw_speeches = (speeches) ->


  # # group by event
  # by_event = _(all_events).chain()
  #   .groupBy((e) -> e.params?.for_event?[0]?.topic_id)
  #   .filter((events) -> events.length > MIN_GROUP_THRESHOLD = 5)

  # by_location = _(all_events).groupBy((d) -> d.params?.in_location?[0]?.topic_id)
  # by_entity = _(all_events).groupBy((d) -> d.params?.pkey?[0]?.topic_id)
  # by_articles_count = _(all_events).groupBy((d) -> d.articles.length)
