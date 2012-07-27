class window.OlympicStream

  constructor: (root_selector) ->
    @root_selector = root_selector

    # Use webkit hw accelerated transitions or not?
    @webkit_accel = document.body.style.WebkitTransform?
    @webkit_lineclamp = document.body.style.WebkitLineClamp?

  # updates the cells on screen given a list of events
  # if events not passed in, then will simply update the layout
  update: (agg_events) ->
    _this = @
    # construct cells
    cells = d3.select(@root_selector).selectAll('.cell').data(agg_events, (d) -> d.id)
    cells.enter()
      .append('div')
      .classed('cell', true)
      .call(-> @each (d) -> _this._construct_event(d, @) )
    cells.exit().remove()

  _construct_event: (d, el) ->
    cell$ = $(el)
    $('<div class="date">').appendTo(cell$).text moment(d.date).format("h:mma, dddd M/DD")
    event$ = $('<h2>').appendTo(cell$)
    $('<div class="name">').appendTo(event$).text(d.label)

    # TODO: Re-enable event images when they are prettier
    # if d.image && (img = get_image(d.image, 100, 100))
    #   event$.append("<img class='event' width='#{img.size[0]}px' height='#{img.size[1]}px' src='#{img.url}'>")

    rels$ = $('<div class="rels">').appendTo(cell$)
    if d.rels.awards
      award_events = _(d.rels.awards).sortBy (d) ->
        switch (d.award.id)
          when 'yC4gq' then 1 # gold medal
          when 'yBQ2g' then 2 # silver medal
          when 'yF5Fy' then 3 # bronze medal
          else 4            # unknown medal

      d3.select($('<div class="relation awards">').appendTo(rels$)[0])
        .selectAll('award')
        .data(award_events)
        .enter()
          .append('div')
          .classed('award', true)
          .call ->
            @call(create_team_flag)
            @append('img')
            @append('div')
              .classed('label', true)
              .text((d) -> d.award.label)
            @append('a').classed('person', true).call(create_link('person'))

    _(['world_records', 'olympic_records', 'advancements', 'eliminations', 'disqualifications', 'injuries', 'cheating']).each (rel_type) ->
      return unless d.rels[rel_type]
      rel = d3.select($('<div class="relation events">').appendTo(rels$)[0])
      rel.append('h3').text(rel_type.replace('_', ' '))

      events = rel.selectAll('event').data _(d.rels[rel_type]).sortBy (d) -> d.date
      events.enter().append('div').classed('event', true)
      events.append('span').classed('date', true).text((d) -> moment(d.date).fromNow())
      events.call(create_team_flag)
      events.append('a').call(create_link('person'))
      events.append('a').call(create_link('team'))
      events.append('a')
        .classed('read_more', true)
        .text('(read more)')
        .attr('target', '_blank')
        .attr('href', (d) -> "https://wavii.com/news/#{d.id}")

create_team_flag = ->
  @append('a')
    .call(create_link('team', true))
    .append('img')
      .classed('flag', true)
      .attr('src', (d) -> get_image(d.team.image, 50, 50).url)
      .attr('title', (d) -> d.team.label)

create_link = (param_key, hide_text=false) ->
  -> @text((d) -> d[param_key]?.label unless hide_text)
      .attr('href', (d) -> "https://wavii.com/topics/#{d[param_key].id}" if d[param_key])
      .attr('target', '_blank')
      .classed('hidden', (d) -> !d[param_key]?)

# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
get_image = (generic_image, width, height) ->
  images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  image = images.find((i) -> i.size[0] >= width).value() || images.last().value()

  if image
    if height
      # scale to fit in box
      width ||= image.size[0]
      height ||= image.size[1]
      scale = Math.min(width / image.size[0], height / image.size[1])
    else
      scale = width / image.size[0]

    image.size = [Math.floor(scale * image.size[0]), Math.floor(scale * image.size[1])]

  image
