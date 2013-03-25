_.mixin(_.string.exports())

g_units = null
g_max_per_year = 5

g_one_month_ago = moment().subtract('days', 30)

window.zoomInit = (data_path) ->
  $.ajax data_path, success: (units) ->
    g_units = _(units).chain()
      .map((u) -> u.moment = moment.unix(u.start_time); u)
      .value()
    initControls()
    start()


initControls = ->
  $('#controls').append(
    """
      <span class="description">Zoom Controls: </span>
      <div class="button more">More</div>
      <div class="button less">Less</div>
    """
  )

  zoomUpdated = ->
    g_max_per_year = Math.max(Math.min(g_max_per_year, 1000), 5)
    visible_unit = _($('.unit')).find((el) -> $(el).visible())

    start()

    if visible_unit
      window.location.href = '#' + $(visible_unit).parent('.year').attr('id')

  $('#controls .more').click ->
    g_max_per_year *= 2
    zoomUpdated()

  $('#controls .less').click ->
    g_max_per_year /= 2
    zoomUpdated()


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
        units = _(d.units).chain()
          .sortBy((u) -> u.score)
          .take(g_max_per_year)
          .sortBy((u) -> u.moment)
          .value()
        $(@).find('h1 .title').text(d.year)
        $(@).find('h1 .description').text(
          "showing Top #{units.length} of #{d.units.length}"
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

