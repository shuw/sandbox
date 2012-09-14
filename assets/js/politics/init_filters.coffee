TYPE_SORT_ORDER = [
  'relation'
  'event'
  'topic'
]

window.init_filters = (events, on_events_selected) ->
  grouped_by_type = {
    'event': group_by_type(10, events, 'event', (d) -> d.params.for_event?.label)
    'relation': group_by_type(10, events, 'relation', (d) -> d.relation_name)
    'topic': group_by_type(20, events, 'topic', (d) -> d.params.pkey?.label)
  }

  select_filter_path = (path) ->
    if path && path != ''
      parts = path.replace(/-/g, ' ').split('/')
      filtered_events = grouped_by_type[parts[0]]?.items[parts[1]]?.items

    unless filtered_events?.length > 0
      path = ''
      filtered_events = events

    unless path == '' and !window.location.hash
      window.location.hash = path.replace(/\s/g, '-')
    on_events_selected(filtered_events)

  sorted_filter_groups = _(grouped_by_type).sortBy((d) -> TYPE_SORT_ORDER.indexOf(d.type))

  root = d3.select('#filters')
  root.append('div').classed('link all', true)
    .text('All')
    .on('click', -> select_filter_path(''))
  root.selectAll('.by_type')
    .data(sorted_filter_groups)
  .enter()
    .append('div').classed('by_type', true)
    .call(-> @append('h2').text((d) -> "#{_(d.type).capitalize()}s"))
    .each((grouped_events) ->
      d3.select(@).selectAll('.link')
        .data((d) -> _(grouped_events.items).values())
      .enter()
        .append('div').classed('link', true)
        .text((d) -> "#{d.key} (#{d.items.length})")
        .on('click', (d) -> select_filter_path("#{grouped_events.type}/#{d.key}"))
    )

  onhashchange = -> select_filter_path(window.location.hash.substring(1))
  window.onhashchange = onhashchange
  onhashchange()


group_by_type = (max_count, events, type, key_func) ->
  {
    type: type
    items: _(sort_by_occurrences(events, key_func)).chain()
      .take(max_count)
      .reduce(((memo, group) -> memo[group.key] = group; memo), {})
      .value()
  }
