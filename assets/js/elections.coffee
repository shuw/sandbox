_.mixin(_.string.exports())

window.elections_init = (data_path) ->
    $.ajax data_path, success: (events) ->
      events_by_relation = _(events)
        .chain()
        .groupBy((event) -> event.relation_type)
        .reject((events, relation_type) ->
          # filter mentions for now...
          relation_type == 'source_published_article_about_subjects' \
          || relation_type == 'author_wrote_article_about_subjects' \
          || relation_type == 'summary' # and summaries
        )
        .sortBy((events, relation_type) -> -events.length)
        .value()


      d3.select('#root')
        .selectAll('.relation')
        .data(events_by_relation)
      .enter()
        .append('div')
        .classed('relation', true)
        .call((d) ->
          @append('h1').text((events) -> "#{events[0].relation_type} (#{events.length})")
        )
        .selectAll('.event')
        .data((events) -> events)
      .enter()
        .append('div')
        .classed('event', true)
        .text((event) -> "#{event.headline} (#{event.news_event_id})")
