MIN_GROUP_THRESHOLD = 5

window.draw_groups = (events) ->
  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  consume_group = (param_key) ->
    return _(events_by_id).chain()
      .values()
      .groupBy((e) -> e.params[param_key]?.topic_id)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length > MIN_GROUP_THRESHOLD
          # delete events from maste rlist so they are consumed
          _(events).each (e) -> delete events_by_id[e.news_event_id]
          {
            date: events[0].date
            param: events[0].params[param_key],
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


draw_speeches = (speeches) ->
  root = d3.select(@)

  # Normalized speeches
  speeches = _(speeches).chain()
    .map((e) ->
      return unless e.params.pkey?
      speaker = e.params.pkey
      gimage = speaker.topic_images?[0]

      {
        name: speaker.label,
        quote: e.params.quote_commonentity?.label,
        image: gimage && _get_image(gimage, 40, 40) || {
          url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png',
          size: [40, 40]
        }
      }
    )
    .compact().value()

  top_speakers = _sort_by_occurrences(speeches, (d) -> d.name)
  root.selectAll('.speaker')
    .data(top_speakers[..4])
  .enter()
    .append('a')
    .classed('speaker', true)
    .call(_avatar_creator())

  prefix = (if top_speakers.length > 5 then "and #{top_speakers.length - 5} others " else "")
  root.append('span').text("#{prefix}gave a speech")


  quotes = _(speeches).filter((d) -> d.quote?)
  root.selectAll('.quote')
    .data(quotes)
  .enter()
    .append('div').classed('quote', true)
    .call(_avatar_creator())
    .append('span')
      .text((d) -> d.quote)


_avatar_creator = (options = {}) ->
  return ->
    @append('img')
      .classed('avatar', true)
      .attr('title', (d) -> d.name)
      .attr('src', (d) -> d.image.url)
      .attr('width', (d) -> (options.size || d.image.size)[0])
      .attr('height', (d) -> (options.size || d.image.size)[1])


# Groups by key and returns the most frequent items first
_sort_by_occurrences = (list, key_func) ->
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
