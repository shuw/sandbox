(window.relations ||= {}).polling_number =
  renderable: (event) ->
    event.params.pley? ||
    event.params.went_up_by_percent? ||
    event.params.went_down_by_percent?

  # TODO: Include subpredicate occurred_at_event if exists
  render: (events) ->
    groups = _(events).groupBy((e) -> e.params.pkey.topic_id)
    debugger