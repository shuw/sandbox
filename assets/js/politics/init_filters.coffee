TYPE_SORT_ORDER = [
  'relation'
  'event'
  'topic'
]

window.init_filters = (events, on_events_selected) ->
  $el = $('#filters')

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
      parts = path.split('/')
      filtered_events = grouped_by_type[parts[0]]?.items[parts[1]]?.items
      $el.find(".link").removeClass('selected')
      $el.find(".link##{parts[0]}_#{parts[1]}").addClass('selected')

    unless filtered_events?.length > 0
      path = ''
      filtered_events = events
      $el.find(".link").removeClass('selected')
      $el.find(".link.all").addClass('selected')


    unless path == '' and !window.location.hash
      window.location.hash = path

    if path != current_path
      on_events_selected(filtered_events)
      current_path = path

      $('html, body').animate({
        scrollTop: $("#root").offset().top
      }, 100);

  sorted_filter_groups = _(grouped_by_type).sortBy((d) -> TYPE_SORT_ORDER.indexOf(d.type))

  root = d3.select($el[0])
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
        .append('div')
        .attr('id', (d) -> "#{grouped_events.type}_#{d.key}")
        .classed('link', true)
        .call(avatar_creator)
        .call(-> @append('span').text((d) -> "#{d.name} (#{d.items.length})"))
        .on('click', (d) -> select_filter_path("#{grouped_events.type}/#{d.key}"))
    )

  onhashchange = -> select_filter_path(window.location.hash.substring(1))
  window.onhashchange = onhashchange
  onhashchange()


group_by_type = (max_count, events, type, name_func, avatar_func, affiliation_func) ->
  {
    type: type
    items: _(sort_by_occurrences(events, (d) -> name_func(d)?.replace(/\s/g, '-'))).chain()
      .take(max_count)
      .reduce(((memo, group) ->
        item = group.items[0]
        group.avatar_image = avatar_func?(item) || {
          url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png'
          size: [40, 40]
        }
        group.name = name_func(item)
        group.affiliation = affiliation_func?(item)
        memo[group.key] = group
        memo
      ),{})
      .value()
  }
