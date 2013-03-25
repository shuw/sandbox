_.mixin(_.string.exports())

g_units = null
g_max_per_year = 4
g_show_hidden_counts = true

g_one_month_ago = moment().subtract('days', 30)

window.zoomInit = (data_path) ->
  $.ajax data_path, success: (units) ->
    g_units = _(units).chain()
      .map((u) -> u.moment = moment.unix(u.start_time); u)
      .value()
    initControls()

initControls = ->
  $('#controls').append(
    """
      <span class="description"></span>
      <div class="button more">More</div>
      <div class="button less">Less</div
    """
  )

  zoomUpdated = (init) ->
    g_max_per_year = Math.max(Math.min(g_max_per_year, 1000), 1)
    $('#controls .description')
      .text("Showing #{g_max_per_year} units / year")
    visible_unit = _($('.unit')).find((el) -> $(el).visible())

    start()

    if visible_unit && !init
      window.location.href = '#' + $(visible_unit).parent('.year').attr('id')

  $('#controls .more').click ->
    g_max_per_year *= 2
    zoomUpdated()

  $('#controls .less').click ->
    g_max_per_year /= 2
    debugger
    zoomUpdated()


  zoomUpdated(true)

start = ->
  year_units = _(g_units).chain()
    .groupBy((u) -> u.moment.year())
    .map((units, year) -> {year: year, units: units})
    .sortBy((d) -> -d.year)
    .value()

  summary = d3.select('#summary')
    .selectAll('.year')
    .data(year_units, (d) -> d.year)
  summary.enter()
    .append('a')
    .classed('year', true)
    .text((d) -> "#{d.year} (#{d.units.length})")
    .attr('href', (d) -> "#year_#{d.year}")
  summary.exit().remove()

  years = d3.select('#root')
    .selectAll('.year')
    .data(year_units, (d) -> d.year)
  years.enter()
    .append('div')
    .classed('year', true)
    .attr('id', (d) -> "year_#{d.year}")
    .append('h1')
      .call(->
        @append('span').classed('title', true)
        @append('span').classed('description', true)
      )
  years
    .call(->
      @each (d) ->
        _(d.units).chain()
          .sortBy((u) -> u.score)
          .each((u, i) -> u.shown = i < g_max_per_year)

        shown_count = 0
        units = []
        hidden_count = 0
        for u in _(d.units).sortBy((u) -> -u.moment)
          if u.shown
            units.push(hidden_count: hidden_count) if hidden_count > 0
            units.push u
            hidden_count = 0
            shown_count += 1
          else
            hidden_count += 1

        units.push(hidden_count: hidden_count) if hidden_count > 0

        $(@).find('h1 .title').text(d.year)
        $(@).find('h1 .description').text(
          "showing #{shown_count} of #{d.units.length}"
        )
        drawUnits @, units
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
      @each (unit) ->
        if unit.hidden_count
          if g_show_hidden_counts
            $(@)
              .addClass('hidden_count')
              .text("... #{unit.hidden_count} more units hidden ...")
          return

        html = renderUnit(@, unit)
        return if !html
        m = unit.moment
        time = if m < g_one_month_ago then m.format("M/DD/YY") else m.fromNow()
        $(@).append(
          html,
          Mustache.render(
            """
              <div class="meta">
                <div title="{{score}}" class="time">{{time}}</div>
              </div>
            """,
            score: unit.score
            time: time
          )
        )
    )
  units.exit().remove()


# TODO:
#   - organize by year
renderUnit = (el, unit) ->
  switch (unit.unit_type)
    when 'ADD_SINGLE_PHOTO'
      return Mustache.render(
        """
          {{#message}}<div class="message">{{message}}</div>{{/message}}
          <img class="photo" width="400" src="{{src}}"></img>
        """,
        src: unit.images[0].uri
        message: unit.message
        score: unit.score
      )

    when 'STATUS_UPDATE'
      return Mustache.render(
        """
          <div class="message">{{message}}</div>
        """,
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
        """
          <div class="unit_type">Can't render {{unit_type}} yet</div>
        """,
        unit_type: unit.unit_type
      )


`
/*! jQuery visible 1.0.0 teamdf.com/jquery-plugins | teamdf.com/jquery-plugins/license */
  (function(c){c.fn.visible=function(e){var a=c(this),b=c(window),f=b.scrollTop();b=f+b.height();var d=a.offset().top;a=d+a.height();var g=e===true?a:d;return(e===true?d:a)<=b&&g>=f}})(jQuery);
`

