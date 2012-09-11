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

  d3.select(@).selectAll('.group')
    .data(groups)
  .enter()
    .append('div').classed('group', true)
    .call(-> @append('h1').text((d) -> d.param.topic.name))
    .each(draw_group)


draw_group = (group) ->
  relation_groups = _(group.events).chain()
    .groupBy((event) -> event.relation_type)
    .map((events, relation_type) ->
      switch relation_type
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
    .append('div').classed('relation', true)
    .call(-> @append('h2').text((d) -> d.relation_type))
    .each((d) -> d.draw_function.call(@, d.events))


draw_speeches = (speeches) ->
  root = d3.select(@)
  root.append('h3').text("#{speeches.length} speeches were made")

  speakers = _(speeches).chain()
    .map((e) ->
      if e.params.pkey?.length
        speaker = e.params.pkey[0]
        gimage = speaker.topic_images?[0]
        {
          name: speaker.label,
          image: gimage && _get_image(gimage, 40, 40) || {
            url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png',
            size: [40, 40]
          }
        }
    )
    .compact().value()

  speakers = _top_occurences(speakers, (d) -> d.name)

  root.selectAll('.speaker')
    .data(speakers[..4])
  .enter()
    .append('a')
    .classed('speaker', true)
    .append('img').call(_bind_image)
    .attr('title', (d) -> d.name)

  prefix = (if speakers.length > 5 then "and #{speakers.length - 5} others " else "")
  root.append('span').text("#{prefix}gave a speech")


  root.selectAll('.speech')
    .data(speeches)
  # quotes = _(speeches).chain()
  #   .map((d) -> d.params.quote_commonentity).compact()
  #   .value()


_bind_image = ->
  @attr('src', (d) -> d.image.url)
  @attr('width', (d) -> d.image.size[0])
  @attr('height', (d) -> d.image.size[1])


_top_occurences = (list, key_func) ->
  _(list).chain()
    .groupBy(key_func || ((d) -> d))
    .sortBy((group, key) -> group.length)
    .map((group) -> group[0])
    .value()

# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
_get_image = (generic_image, width, height) ->
  _images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  image = _images.find((i) -> i.size[0] >= width).value() || _images.last().value()

  if image
    if height
      # scale to fit in box
      width ||= image.size[0]
      height ||= image.size[1]
      scale = Math.min(width / image.size[0], height / image.size[1])
    else
      scale = width / image.size[0]

    image.size = [scale * image.size[0], scale * image.size[1]]

  image
