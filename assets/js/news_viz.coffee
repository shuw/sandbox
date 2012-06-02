width = 2000
height = 1000
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
        .filter((n) -> !n.errors)
        .groupBy('relation_type')
        .map(
          (news, relation_type) ->
            {
              name: relation_type,
              children: _.chain(news).map(
                (n) ->
                  if n.summary
                    _(n.summary.entities).map((e) -> e.topic.name)
                  else
                    _.chain(n.params).flatten().map( (p) -> p.topic?.name ).value()
                )
                .compact()
                .flatten()
                .groupBy((topic_name) -> topic_name)
                .map((values, topic_name) -> { name: topic_name, size: values.length })
                .value()
            }
        )
        .value()
      }

    div.data([json]).selectAll('div')
        .data(treemap.nodes)
      .enter().append('div')
        .attr('class', 'cell')
        .style('background', (d) -> if d.children then color(d.name) else null)
        .call(cell)
        .text( (d) -> if d.children then null else d.name )

    d3.select('#size').on 'click', ->
      div.selectAll('div')
          .data(treemap.value((d) -> d.size))
        .transition()
          .duration(1500)
          .call(cell)

      d3.select('#size').classed('active', true)
      d3.select('#count').classed('active', false)

    d3.select('#count').on 'click', ->
      div.selectAll('div')
          .data(treemap.value((d) -> 1))
        .transition()
          .duration(1500)
          .call(cell)

      d3.select('#size').classed('active', false)
      d3.select('#count').classed('active', true)

  cell = ->
    @
      .style('left', (d) -> d.x + 'px' )
      .style('top', (d) -> d.y + 'px' )
      .style('width', (d) -> Math.max(0, d.dx - 1) + 'px' )
      .style('height', (d) -> Math.max(0, d.dy - 1) + 'px' )
