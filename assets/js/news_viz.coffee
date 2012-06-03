width = Math.max(800, $(window).width() - 40)
height = 2000
color = d3.scale.category20c()

$ ->
  treemap = d3.layout.treemap()
      .size([width, height])
      .sticky(true)
      .value((d) -> d.size)

  chart = d3.select('#chart').append('div')
      .style('position', 'relative')
      .style('width', width + 'px')
      .style('height', height + 'px')

  d3.json '/data/news_data.json', (news) ->
    news = filter_and_sort(news)
    return if news.length < 2

    $('#date-range').text "Showing events from " + news[0].date.fromNow() + ' to ' + news[news.length - 1].date.fromNow()

    # Layout
    chart.data([get_news_tree(news)])
      .selectAll('div')
        .data(treemap.nodes)
      .enter()
        .append('div')
        .style('background', (d) -> if d.type == 'topic' then color(d.relation_type) else null)
        .call(cell)

    # Popover
    chart.selectAll('div')
      .on('mouseover', ((data)->
        if data.type == 'topic'
          images = data.images?.slice(0, 1) || []

          selection = d3.select('#pop-over')
            .data([data])
            .text((d) -> d.name)
            .style('font-size', '30px')
            .style('display', 'block')

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
                .classed('news_event', true)
        ), true)

    d3.select("#article-count").on "click", -> update_size((d) -> d.articles_count)
    d3.select("#event-count").on "click", -> update_size((d) -> d.size)

  cell = ->
    @text((d) -> d.name )
      .attr('title', (d) -> d.name )
      .attr('class', (d) -> 'cell ' + d.type)
      .style('left', (d) -> d.x + 'px' )
      .style('top', (d) -> d.y + 'px' )
      .style('width', (d) -> Math.max(0, d.dx - 1) + 'px' )
      .style('height', (d) -> Math.max(0, d.dy - 1) + 'px' )

  update_size = (get_size) ->
    chart.selectAll("div")
      .data(treemap.value(get_size))
      .transition().duration(1500)
      .call(cell)

filter_and_sort = (news) ->
  news = _(news).filter((n) -> !n.errors && !n.staff_only )
  _(news).each((n) ->
      n.date = moment(n.date)
      n.relation_type = n.relation_type.split('_').join(' ')
    )
  _(news).sortBy((n) -> n.date)

# create tree: relations - topics - events
get_news_tree = (news) ->
  {
    children: _.chain(news)
      .groupBy('relation_type')
      .map((news, relation_type) ->
        {
          type: 'relation'
          name: relation_type,
          children: _.chain(news).map((n) ->
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
                articles_count: _.chain(matches).map((d) -> d.event.articles).flatten().size().value()
                images: matches[0].topic_images,
                events: _(matches).map((d) -> d.event)
              })
            .value()
        }
      )
      .value()
  }