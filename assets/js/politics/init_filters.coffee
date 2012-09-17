TYPE_SORT_ORDER = [
  'relation'
  'event'
  'topic'
]

window.init_filters = (events, on_events_selected) ->
  grouped_by_type = {
    'event': group_by_type(10, events, 'event',
      (d) -> d.params.for_event?.topic?.name,
      (d) -> d.params.for_event.avatar_image,
      (d) -> d.params.for_event.affiliation,
    )
    'relation': group_by_type(10, events, 'relation', (d) -> d.relation_name)
    'topic': group_by_type(20, events, 'topic',
      (d) -> d.params.pkey?.topic?.name,
      (d) -> d.params.pkey.avatar_image,
      (d) -> d.params.pkey.affiliation,
    )
  }

  current_path = null
  select_filter_path = (path) ->
    if path && path != ''
      parts = path.replace(/-/g, ' ').split('/')
      filtered_events = grouped_by_type[parts[0]]?.items[parts[1]]?.items

    unless filtered_events?.length > 0
      path = ''
      filtered_events = events

    unless path == '' and !window.location.hash
      window.location.hash = path.replace(/\s/g, '-')

    if path != current_path
      on_events_selected(filtered_events)
      current_path = path

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
        .call(avatar_creator)
        .call(-> @append('span').text((d) -> "#{d.key} (#{d.items.length})"))
        .on('click', (d) -> select_filter_path("#{grouped_events.type}/#{d.key}"))
    )

  onhashchange = -> select_filter_path(window.location.hash.substring(1))
  window.onhashchange = onhashchange
  onhashchange()


group_by_type = (max_count, events, type, key_func, avatar_func, affiliation_func) ->
  {
    type: type
    items: _(sort_by_occurrences(events, key_func)).chain()
      .take(max_count)
      .reduce(((memo, group) ->
        item = group.items[0]
        group.avatar_image = avatar_func?(item) || {
          url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png'
          size: [40, 40]
        }
        group.affiliation = affiliation_func?(item)
        memo[group.key] = group
        memo
      ),{})
      .value()
  }
