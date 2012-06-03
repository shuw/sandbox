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
            children: _.chain(news).map((n) ->
              # map news events to all their topics
              params = (if n.summary then _.chain(n.summary.entities) else _.chain(n.params).flatten())
              params
                .filter((p) -> p.topic && !p.topic.staff_only )
                .map((p) -> {
                    topic_name: p.topic.name,
                    topic_images: p.topic_images,
                    event: n
                  }
                ).value()
              )
              .flatten()
              .groupBy((d) -> d.topic_name)
              .map((matches, topic_name) ->
                {
                  type: 'topic'
                  relation_type: matches[0].event.relation_type
                  name: topic_name,
                  size: matches.length
                  images: matches[0].topic_images,
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
      .on('mouseover', ((data)->
        if data.type == 'topic'
          images = data.images?.slice(0, 1) || []

          selection = d3.select('#pop-over')
            .data([data])
            .text((d) -> d.name)
            .style('font-size', '30px')

          selection.selectAll('img')
            .data(images)
            .enter()
              .append('img')
              .attr('src', (d) -> d.sizes[0].url)

          selection.selectAll('div')
            .data(data.events)
            .enter()
                .append('div')
                .text((d) -> d.headline)
                .style('font-size', '18px')
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
