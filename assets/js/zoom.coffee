g_units = null
g_max_per_year = 4
g_show_hidden_counts = true
g_show_unrecognized_types = true
g_one_month_ago = moment().subtract('days', 30)

window.zoomInit = ->
  data_file = window.location.search.split('?')[1]?.split('=')[1]
  data_path = '/data/' + if data_file then data_file else 'zoom.json'
  $.ajax data_path, success: (units) ->
    g_units = _(units).chain()
      .filter((u) ->
        return true if g_show_unrecognized_types
        switch (u.unit_type)
          when 'ADD_SINGLE_PHOTO' then return true
          when 'STATUS_PHOTO' then return true
          when 'LINK' then return true
          else return false
      )
      .map((u) -> u.moment = moment.unix(u.start_time); u)
      .value()

    initControls()


initControls = ->
  $('#controls').append("""
    <span class="description"></span>
    <div class="button more">More</div>
    <div class="button less">Less</div>
  """)

  zoomUpdated = ->
    g_max_per_year = Math.max(Math.min(g_max_per_year, 1000), 1)
    $('#controls .description').text("Showing #{g_max_per_year} units / year")
    start()

  $('#controls .more').click -> g_max_per_year *= 2; zoomUpdated()
  $('#controls .less').click -> g_max_per_year /= 2; zoomUpdated()
  zoomUpdated()


start = ->
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
          .sortBy((u) -> u.score)
          .each((u, i) -> u.shown = i < g_max_per_year)

        shown_count = 0
        units = []
        hidden_count = 0
        for u in _(d.units).sortBy((u) -> -u.moment)
          if u.shown
            if g_show_hidden_counts && hidden_count > 0
              units.push(hidden_count: hidden_count, unique_id: hidden_count)
            units.push u
            hidden_count = 0
            shown_count += 1
          else
            hidden_count += 1

        if g_show_hidden_counts && hidden_count > 0
          units.push(hidden_count: hidden_count, unique_id: hidden_count)

        $(@).find('h1 .title').text(d.year)
        $(@).find('h1 .description')
          .text("showing #{shown_count} of #{d.units.length}")
        drawUnits(@, units)
    )
  years.exit().remove()


drawUnits = (el, units) ->
  units = d3.select(el)
    .selectAll('.unit')
    .data(units, (u) -> u.unique_id)
  units.enter()
    .append('div')
    .classed('unit', true)
    .call(->
      @each((unit) ->
        if unit.hidden_count
          $(@).addClass('hidden_count')
            .text("... #{unit.hidden_count} units hidden ...")
          return

        return if !(html = renderUnit(@, unit))

        if unit.moment < g_one_month_ago
          time = unit.moment.format("M/DD/YY")
        else
          time = unit.moment.fromNow()

        $(@).append(
          html,
          Mustache.render(
            '<div class="meta" title="{{score}}">{{time}}</div>',
            score: unit.score
            time: time
          )
        )
      )
    )
  units.exit().remove()
  units.order()


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
        '<div class="message">{{message}}</div>',
        message: unit.message
        score: unit.score
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

