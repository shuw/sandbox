g_events_by_rel = {}

window.olympics_init = (data_path) ->
  $.ajax data_path, success: (events) ->
    g_events_by_rel = normalize_events(events)
    update_scoreboard()


update_scoreboard = ->
  by_team = _(g_events_by_rel['awards']).chain()
    .groupBy((d) -> d.team.label)
    .map((events) ->
      awards = _(events).groupBy((d) -> d.award.label)
      {
        team: events[0].team
        count: events.length
        awards: [awards['Gold Medal'] || [], awards['Silver Medal'] || [], awards['Bronze Medal'] || []]
      })
    .sortBy((d) -> -d.count)
    .value()

  teams = d3.select('#scoreboard').selectAll('.team')
    .data(by_team, (d) -> d.team.id)
  teams.enter()
    .append('div')
    .classed('team', true)
    .call ->
      @append('img')
        .attr('src', (d) -> d.team.image.url)
        .attr('height', 30)
        .attr('width', 30)
      @append('span').classed('name', true)
        .text((d) -> d.team.label)
      @append('span').classed('awards', true)
        .selectAll('.award')
        .data((d) -> d.awards)
        .enter()
          .append('span').classed('award', true)
          .text((d) -> d.length)


  teams.exit().remove()


# returns { normalized_relations -> [normalized_events] }
normalize_events = (events) ->
  _events = _(events).chain()

  # normalize events
  rels = _({
    person_wins_event:                    { team: 'for__organization', person: 'left_pkey', award: 'the_award', event: 'right_pkey' }
    organization_wins_award:              { team: 'left_pkey', award: 'right_pkey' }
    person_advances_in_event:             { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    organization_advances_in_event:       { team: 'left_pkey', event: 'right_pkey' }
    person_sets_olympic_record:           { team: 'for__organization', person: 'pkey', event: 'in_event' }
    person_sets_world_record:             { team: 'for__organization', person: 'pkey', event: 'in_event' }
    organization_sets_olympic_record:     { team: 'pkey', event: 'in_event' }
    organization_sets_world_record:       { team: 'pkey', event: 'in_event' }
    person_disqualified_from_event:       { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    organization_disqualified_from_event: { team: 'left_pkey', event: 'right_pkey' }
    person_eliminated_from_event:         { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    organization_eliminated_from_event:   { team: 'left_pkey', event: 'right_pkey' }
    person_injured_at_event:              { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    person_suspected_of_cheating:         { team: 'for__organization', person: 'pkey' }
  }).reduce(((rels, mappings, relation_type) ->
    rels[relation_type] = _events
      .filter((e) -> e.relation_type == relation_type)
      .map((e) ->
        _(mappings).reduce(((event, param_key, normalized_key) ->
          p = e.params[param_key]?[0]
          if p
            event[normalized_key] =
              id:    p.topic_id
              label: p.label
              image: p.topic_images? && get_image(p.topic_images[0], 100, 100)
          else
            console.warn "#{relation_type} missing #{param_key}"
          event
        ), {})
      ).value()
    rels
  ), {})


  # normalize relations
  _({
    awards: ['person_wins_event', 'organization_wins_award']
    advancements: ['person_advances_in_event', 'organization_advances_in_event']
  }).reduce(((normalized_rels, relation_types, normalized_relation_type) ->
    normalized_rels[normalized_relation_type] = _(relation_types).chain().map((r) -> rels[r] || []).flatten().value()
    normalized_rels
  ), {})

# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width, height) ->
  _images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  image = _images.find((i) -> i.size[0] >= width).value() || _images.last().value()
  return unless image

  if height
    # scale to fit in box
    width ||= image.size[0]
    height ||= image.size[1]
    scale = Math.min(width / image.size[0], height / image.size[1])
  else
    scale = width / image.size[0]

  image.size = [scale * image.size[0], scale * image.size[1]]
  image