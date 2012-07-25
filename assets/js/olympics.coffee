window.olympics_init = (data_path) ->
  $.ajax data_path, success: (events) -> init(events)


init = (events) ->
  _events = _(events).chain()

  for_relations = (rels) ->
    _(rels).each


  for_relation = (r) -> _events.filter (e) -> e.relation_type == r
  get_param = (e, name) ->
    e.params[name]?.length && (p = e.params[name][0]) && {
      label: p.label
      image: p.topic_images? && get_image(p.topic_images[0], 200, 200)
    }

  # TODO:
  # "person_injured_at_event",
  # "person_suspected_of_cheating"

  _awards = for_relation('person_wins_event').map (e) ->
    {
      person: get_param(e, 'left_pkey')
      event: get_param(e, 'right_pkey')
      team: get_param(e, 'for__organization')
      award: get_param(e, 'the_award')
      country: label: 'United States'
    }
  _org_awards = for_relation('organization_wins_award').map (e) ->
    {
      team: get_param(e, 'left_pkey')
      award: get_param(e, 'right_pkey')
      event: get_param(e, 'in_event')
    }

  _person_advances = for_relation('person_advances_in_event').map (e) ->
    {
      person: get_param(e, 'left_pkey')
      event: get_param(e, 'right_pkey')
      team: get_param(e, 'for__organization')
    }

  _org_advances = for_relation('organization_advances_in_event').map (e) ->
    {
      team: get_param(e, 'left_pkey')
      event: get_param(e, 'right_pkey')
    }

  _person_record = for_relation('person_sets_olympic_record').map (e) ->
    {
      person: get_param(e, 'pkey')
      team: get_param(e, 'for__organization')
      event: get_param(e, 'in_event')
    }
  _person_world_record = for_relation('person_sets_world_record').map (e) ->
    {
      person: get_param(e, 'pkey')
      team: get_param(e, 'for__organization')
      event: get_param(e, 'in_event')
    }

  _org_record = for_relation('organization_sets_olympic_record').map (e) ->
    {
      team: get_param(e, 'pkey')
      event: get_param(e, 'in_event')
    }
  _org_world_record = for_relation('organization_sets_world_record').map (e) ->
    {
      team: get_param(e, 'pkey')
      event: get_param(e, 'in_event')
    }

  _person_disqualified = for_relation('person_disqualified_from_event').map (e) ->
    {
      person: get_param(e, 'left_pkey')
      team: get_param(e, 'for__organization')
      event: get_param(e, 'right_pkey')
    }

  _org_disqualified = for_relation('organization_disqualified_from_event').map (e) ->
    {
      team: get_param(e, 'left_pkey')
      event: get_param(e, 'right_pkey')
    }

  _person_disqualified = for_relation('person_eliminated_from_event').map (e) ->
    {
      person: get_param(e, 'left_pkey')
      team: get_param(e, 'for__organization')
      event: get_param(e, 'right_pkey')
    }

  _org_disqualified = for_relation('organization_eliminated_from_event').map (e) ->
    {
      team: get_param(e, 'left_pkey')
      event: get_param(e, 'right_pkey')
    }



# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width, height) ->
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
