width = Math.max(800, $(window).width() - 40)
height = 2000
color = d3.scale.category20c()

$ ->
  treemap = d3.layout.treemap()
      .size([width, height])
      .sticky(true)
      .value( (d) -> d.size)

  div = d3.select('#chart').append('div')
      .style('position', 'relative')
      .style('width', width + 'px')
      .style('height', height + 'px')

  d3.json '/data/news_data.json', (news) ->
    json = {
      children: _.chain(news)
        .filter((n) -> !n.errors && !n.staff_only )
        .groupBy('relation_type')
        .map((news, relation_type) ->
          {
            type: 'relation_type'
            name: relation_type,
            children: _.chain(news).map(
                (n) ->
                  (
                    if n.summary
                      topics = _.chain(n.summary.entities).map((e) -> e.topic)
                    else
                      topics = _.chain(n.params).flatten().map((p) -> p.topic)
                  ).compact().filter((t) -> !t.staff_only ).map((t) -> {
                      topic_name: t.name,
                      event: n
                    }
                  ).value())
              .flatten()
              .groupBy((d) -> d.topic_name)
              .map((matches, topic_name) ->
                {
                  name: topic_name,
                  size: matches.length
                  events: _(matches).map((d) -> d.event)
                })
              .value()
          }
        )
        .value()
      }

    div.data([json]).selectAll('div')
        .data(treemap.nodes)
      .enter()
        .append('div')
        .attr('class', 'cell')
        .style('background', (d) -> if d.children then color(d.name) else null)
        .call(cell)
        .text( (d) -> if d.children then null else d.name )

    div.selectAll('div')
      .on('mouseover', ->
        node = d3.select(@)
        d3.select('#pop-over')
          .data([node.datum()])
          .text((d) -> d.name)
          .style('font-size', '30px')
          .selectAll('div')
          .data(node.datum().events)
          .enter()
              .append('div')
              .text((d) -> d.headline)
              .style('font-size', '15px')
      )


  cell = ->
    @
      .style('left', (d) -> d.x + 'px' )
      .style('top', (d) -> d.y + 'px' )
      .style('width', (d) -> Math.max(0, d.dx - 1) + 'px' )
      .style('height', (d) -> Math.max(0, d.dy - 1) + 'px' )
      .style('color', 'gray')
      .style('font-size', '10px')
