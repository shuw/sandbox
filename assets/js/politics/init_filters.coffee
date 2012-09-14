TYPE_SORT_ORDER = {
  'relation': 1
  'topic': 2
}

window.init_filters = (events, on_events_selected) ->
  grouped_by_type = {}

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


  group_by_type = (type, key_func) ->
    grouped_events = grouped_by_type[type] = {
      items: {}
      type: type
    }
    _(sort_by_occurrences(events, key_func)).each (group) ->
      grouped_events.items[group.key] = group

  draw_filters = (grouped_events) ->
    root = d3.select(@)

    root.selectAll('.link')
      .data((d) -> _(grouped_events.items).values()[..20])
    .enter()
      .append('div').classed('link', true)
      .text((d) -> "#{d.key} (#{d.items.length})")
      .on('click', (d) -> select_filter_path("#{grouped_events.type}/#{d.key}"))

  group_by_type('topic', (d) -> d.params.pkey?.label)
  group_by_type('relation', (d) -> d.relation_type)

  sorted_filter_groups = _(grouped_by_type).sortBy((d) -> TYPE_SORT_ORDER[d.type])

  root = d3.select('#filters')
  root.append('div').classed('link all', true)
    .text('All')
    .on('click', -> select_filter_path(''))
  root.selectAll('.by_type')
    .data(sorted_filter_groups)
  .enter()
    .append('div').classed('by_type', true)
    .call(-> @append('h2').text((d) -> "#{_(d.type).capitalize()}s"))
    .each(draw_filters)

  onhashchange = -> select_filter_path(window.location.hash.substring(1))
  window.onhashchange = onhashchange
  onhashchange()
