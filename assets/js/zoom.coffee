# TODO: aggregate life events

_.mixin(_.string.exports())

g_max_per_year = 4
g_friends_to_show = 80

g_units = null
g_show_hidden_counts = true
g_show_unrecognized_types = false
g_one_month_ago = moment().subtract('days', 30)

window.zoomInit = ->
  zoom_user = getQueryVariable('for')
  if zoom_user
    showZoom(zoom_user)
  else
    # show timeleine for a single user
    user = getQueryVariable('user') || 'default'
    $.ajax "/data/#{user}_timeline.json", success: (units) ->
      g_units = processUnits(units)
      draw()


g_friends = {}
g_timelines = {}
g_search_terms = []
g_toggle_on = true
showZoom = (user) ->
  g_show_unrecognized_types = false

  $('#sidebar').removeClass('hidden')

  $('<a href="#">').text('Toggle all').appendTo('#sidebar').click(->
    g_toggle_on = !g_toggle_on
    $('#sidebar .friends .friend').toggleClass('selected', g_toggle_on)
    updateFriends()
  )

  $('#sidebar .search').on('keyup', _.debounce((->
    g_search_terms = tokenize($(@).val())
    showTimelines()
  ), 500))

  $.ajax "/data/#{user}_zoom/friends.json", success: (friends) ->
    # Pick top friends
    _(friends).chain()
      .sortBy((f) -> -f.coefficient)
      .map((f) -> f.selected = true; f)
      .take(g_friends_to_show)
      .each((f) -> g_friends[f.id] = f)


    still_loading = _(g_friends).size()
    gotTimeline = (f) ->
      (units) ->
        units = processUnits(units)
        _(units).each((u) -> u.owner_id = f.id)
        g_timelines[f.id] = units
        updateFriends() unless --still_loading

    for friend in _(g_friends).values()
      $.ajax "/data/#{user}_zoom/#{friend.id}_timeline.json",
        success: gotTimeline(friend)
        error: -> updateFriends() unless --still_loading


updateFriends = ->
  sidebar = d3.select('#sidebar .friends')
    .selectAll('.friend')
    .data(_(g_friends).values(), (d) -> d.id)
  sidebar.enter()
    .append('div')
    .classed('friend', true)
    .attr('id', (f) -> "friend_#{f.id}")
    .classed('selected', (f) -> f.selected)
    .call(-> @each((f) -> $(@).append(renderUser(f))))
  sidebar.call(-> @each((f) -> f.selected = $(@).hasClass('selected')))

  showTimelines()


showTimelines = ->
  g_units = _(g_timelines).chain()
    .filter((g_timelines, id) -> g_friends[id].selected)
    .flatten(true)
    .filter((u) ->
      for term in g_search_terms
        unless u.tokens[term]
          return false
      return true
    )
    .value()
  draw()


g_controls_initialized = false
draw = ->
  zoomUpdated = ->
    g_max_per_year = Math.max(Math.min(g_max_per_year, 1000), 1)
    $('#controls .description').text("Showing #{g_max_per_year} units / year")
    drawYears()

  if !g_controls_initialized
    g_controls_initialized = true
    $('#controls').append("""
      <span class="description"></span>
      <div class="button more">More</div>
      <div class="button less">Less</div>
    """)

    $('#controls .more').click -> g_max_per_year *= 2; zoomUpdated()
    $('#controls .less').click -> g_max_per_year /= 2; zoomUpdated()

  zoomUpdated()


drawYears = ->
  year_units = _(g_units).chain()
    .groupBy((u) -> u.moment.year())
    .map((units, year) -> {year: year, units: units})
    .sortBy((d) -> -d.year)
    .value()
  years = d3.select('#root')
    .selectAll('.year')
    .data(year_units, (d) -> d.year)
  years.enter()
    .append('div')
    .classed('year', true)
    .append('h1')
    .call(->
      @append('span').classed('title', true)
      @append('span').classed('description', true)
    )
  years.call(->
    @each (d) ->
      _(d.units).chain()
        .sortBy((u) -> -u.score)
        .each((u, i) -> u.shown = i < g_max_per_year)

      shown_count = 0
      units = []
      hidden_units = []
      for u in _(d.units).sortBy((u) -> -u.moment)
        if u.shown
          if g_show_hidden_counts && hidden_units.length
            units.push(createHiddenUnit(hidden_units))
          units.push u
          hidden_units = []
          shown_count += 1
        else
          hidden_units.push(u)

      if g_show_hidden_counts && hidden_units.length
          units.push(createHiddenUnit(hidden_units))

      $(@).find('h1 .title').text(d.year)
      $(@).find('h1 .description')
        .text("showing #{shown_count} of #{d.units.length}")
      drawUnits(@, units)
    )
  years.order()
  years.exit().remove()


createHiddenUnit = (units) ->
  unique_id = "hidden_" + _(units).map((u) -> u.unique_id).join()
  return {
    hidden_units: units
    unique_id: unique_id
  }


drawUnits = (el, units) ->
  units = d3.select(el)
    .selectAll('.unit')
    .data(units, (u) -> u.unique_id)
  units.enter()
    .append('div')
    .classed('unit', true)
    .call(->
      @each((unit) ->
        if unit.hidden_units
          $(@).addClass('hidden_count')
            .text("... #{unit.hidden_units.length} units hidden ...")
            .click(=>
              $(@).removeClass('unit').text('').off()

              # draw hidden units, but hide excess in another hidden unit
              # recursiveness!
              units = unit.hidden_units[..5]
              excess_units = unit.hidden_units[5..]
              if excess_units.length
                units.unshift(createHiddenUnit(excess_units))

              drawUnits(@, units)
            )
          return

        return if !(html = renderUnit(@, unit))

        if unit.moment < g_one_month_ago
          time = unit.moment.format("M/DD/YY")
        else
          time = unit.moment.fromNow()

        friend = unit.owner_id && g_friends[unit.owner_id]
        if friend
          $(@).addClass('has_friend_info')
          prefix = $('<div class="friend_section">').append(
            renderUser(friend),
            $('<div class="name">').text(_(friend.name).words()[0])
          )
        else
          prefix = ''

        $(@).append(
          prefix
          $('<div class="contents"></div>').addClass(unit.unit_type).append(html),
          Mustache.render(
            '<div class="meta" title="{{type}} {{score}}">{{time}}</div>',
            type: unit.unit_type
            score: unit.score
            time: time
          )
        )
      )
    )
  units.exit().remove()
  units.order()


renderUser = (user) ->
  $(Mustache.render(
    '<img class="profile_pic" title="{{name}}" src={{profile_pic}}></img>',
    user
  )).click(->
    $("#friend_#{user.id}").toggleClass('selected')
    updateFriends()
  )

renderUnit = (el, unit) ->
  switch (unit.unit_type)
    when 'ADD_SINGLE_PHOTO'
      return Mustache.render("""
          {{#message}}<div class="message">{{message}}</div>{{/message}}
          <img class="photo" width="250" src="{{src}}"></img>""",
        src: unit.images[0].uri
        message: unit.message
        score: unit.score
      )

    when 'STATUS_UPDATE'
      return Mustache.render(
        '<div>{{message}}</div>',
        message: unit.message
        score: unit.score
      )
    
    when 'EXPERIENCE'
      return Mustache.render(
        """
          {{#message}}<div class="message">{{message}}</div>{{/message}}
          <div>
            <img class="icon" src="http://www.facebook.com/{{icon}}"></img>
            <span class="title">{{description}}: {{location}} {{name}}</span>
          </div>
        """, unit
      )

    when 'LINK'
      return Mustache.render(
        """
          {{#message}}<div class="message">{{message}}</div>{{/message}}
          <div class="share">
            <div class="title">{{title}}</div>
            <div class="blurb">{{blurb}}</div>
          </div>
        """,
        message: unit.message
        score: unit.score
        title: unit.share.title
        blurb: unit.share.main_blurb
      )
  
    else
      return Mustache.render(
        '<div class="unit_type">Can\'t render {{unit_type}} yet</div>',
        unit_type: unit.unit_type
      )


processUnits = (units) ->
  return _(units).chain()
    .filter((u) ->
      switch (u.unit_type)
        when 'ADD_SINGLE_PHOTO'
          return true
        when 'STATUS_UPDATE'
          return true if u.message
        when 'EXPERIENCE'
          if u.description && u.description != 'Other Life Event'
            u.to_tokenize = [u.message, u.description].join(' ')
            return true
        when 'LINK'
          if u.message
            u.to_tokenize = \
              [u.message, u.share.title, u.share.main_blurb].join(' ')
            return true
        else return g_show_unrecognized_types

      return false
    )
    .map((u) ->
      u.moment = moment.unix(u.start_time)
      u.tokens = {}
      for token in tokenize(u.to_tokenize || u.message)
        u.tokens[token] = true
      u
    )
    .value()


tokenize = (str) ->
  _((str || '').replace(/[\.,-\/#!$%\^&\*;:{}=\-_`~()]/g,"").toUpperCase())
    .chain().words().value()


`window.getQueryVariable = function(variable) {
    var query = window.location.search.substring(1);
    var vars = query.split('&');
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split('=');
        if (decodeURIComponent(pair[0]) == variable) {
            return decodeURIComponent(pair[1]);
        }
    }
    console.log('Query variable %s not found', variable);
}`
