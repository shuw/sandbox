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
    news = _.chain(news).filter((n) -> !n.errors && !n.staff_only )
    news.each((n) ->
        n.date = new Date(n.date)
        n.relation_type = n.relation_type.split('_').join(' ')
      )
    news = news.sortBy((n) -> n.date)

    json = {
      children: news
        .groupBy('relation_type')
        .map((news, relation_type) ->
          {
            type: 'relation'
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
                  type: 'topic'
                  relation_type: matches[0].event.relation_type
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
        .style('background', (d) -> if d.type == 'topic' then color(d.relation_type) else null)
        .call(cell)

    div.selectAll('div')
      .on('mouseover', ((data, evt)->
        if data.type == 'topic'
          d3.select('#pop-over')
            .data([data])
            .text((d) -> d.name)
            .style('font-size', '30px')
            .selectAll('div')
            .data(data.events)
            .enter()
                .append('div')
                .text((d) -> d.headline)
                .style('font-size', '15px')
        ), true)

  cell = ->
    @
      .text( (d) -> d.name )
      .classed('relation', (d) -> d.children)
      .classed('topic', (d) -> d.events)
      .style('left', (d) -> d.x + 'px' )
      .style('top', (d) -> d.y + 'px' )
      .style('width', (d) -> Math.max(0, d.dx - 1) + 'px' )
      .style('height', (d) -> Math.max(0, d.dy - 1) + 'px' )
