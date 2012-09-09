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

window.elections_init = (data_path) ->
  $.ajax data_path, success: (events) ->

    # Normalize events and reverse sort by date
    events = _(events).chain()
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

    draw_grouped_events(events)
    draw_raw_data(events)


draw_grouped_events = (events, min_group_threshold = 5) ->
  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  consume_group = (param_key) ->
    return _(events_by_id).chain()
      .values()
      .groupBy((e) -> e.params[param_key]?[0]?.topic_id)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length > min_group_threshold
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

  # # group by event
  # by_event = _(all_events).chain()
  #   .groupBy((e) -> e.params?.for_event?[0]?.topic_id)
  #   .filter((events) -> events.length > min_group_threshold)

  # by_location = _(all_events).groupBy((d) -> d.params?.in_location?[0]?.topic_id)
  # by_entity = _(all_events).groupBy((d) -> d.params?.pkey?[0]?.topic_id)
  # by_articles_count = _(all_events).groupBy((d) -> d.articles.length)


# Draw raw data for exploring
draw_raw_data = (events) ->
  events_by_relation = _(events).groupBy((event) -> event.relation_type)
  grouped_events = _(events_by_relation).chain()
    .sortBy((events) -> -events.length)
    .map((events) ->
      {
        events: events,
        param_histogram: _(events).chain()
          .map((e) -> _(e.params).keys())
          .flatten()
          .groupBy((k) -> k)
          .map((l, k) -> { count: l.length, name: k })
          .sortBy('count')
          .value()
      }
    )
    .value()

  relations_sel = d3.select('#raw_headlines')
    .selectAll('.relation')
    .data(grouped_events)
  .enter()
    .append('div')
    .classed('relation', true)
    .call(-> @append('h1').text((d) -> "#{d.events[0].relation_type} (#{d.events.length})"))

  relations_sel.append('ul').selectAll('.param')
    .data((d) -> d.param_histogram)
  .enter()
    .append('li').classed('param', true)
    .text((p) -> "#{p.name} (#{p.count})")

  relations_sel.append('ul').selectAll('.event')
    .data((d) -> d.events)
  .enter()
    .append('li').classed('event', true)
    .text((e) -> "#{e.headline} (#{e.news_event_id})")
