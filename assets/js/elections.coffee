_.mixin(_.string.exports())

window.elections_init = (data_path) ->
    $.ajax data_path, success: (events) ->
      events_by_relation = _(events).groupBy((event) -> event.relation_type)

      # Normalize events and reverse sort by date
      _(events).each((e) -> e.date = new Date(e.date))
      events = _(events).chain()
        .reject((e) ->
            # filter mentions for now...
            e.relation_type == 'source_published_article_about_subjects' \
            || e.relation_type == 'author_wrote_article_about_subjects' \
            || e.relation_type == 'author_from_source_wrote_article_about_subjects' \
            || e.relation_type == 'authors_wrote_articles_about_subject' \
            || e.relation_type == 'summary' # and summaries
        )
        .sortBy((e) -> -e.date)
        .value()

      group_stuff(events)

      grouped_events = _(events_by_relation).chain()
        .sortBy((events) -> -events.length)
        .value()

      d3.select('#root')
        .selectAll('.relation')
        .data(grouped_events)
      .enter()
        .append('div')
        .classed('relation', true)
        .call(-> @append('h1').text((events) -> "#{events[0].relation_type} (#{events.length})"))
        .selectAll('.event')
        .data((events) -> events)
      .enter()
        .append('div')
        .classed('event', true)
        .text((e) -> "#{e.headline} (#{e.news_event_id})")


group_stuff = (events, min_group_threshold = 5) ->
  events_by_id = _(events).reduce(((m, e) -> m[e.news_event_id] = e; m), {})

  consume_group = (param_key) ->
    return _(events_by_id).chain()
      .values()
      .groupBy((e) -> e.params[param_key]?[0]?.topic_id)
      .map((events, topic_id) ->
        if topic_id != 'undefined' && events.length > min_group_threshold
          # delete events from maste rlist so they are consumed
          _(events).each (e) -> delete events_by_id[e.news_event_id]
          {
            date: events[0].date
            param: events[0].params[param_key][0],
            events: events
          }
      ).compact().value()

  by_occured_at_event = consume_group('occurred_at_event')
  debugger

  # # group by event
  # by_event = _(all_events).chain()
  #   .groupBy((e) -> e.params?.occurred_at_event?[0]?.topic_id)
  #   .filter((events) -> events.length > min_group_threshold)

  # by_location = _(all_events).groupBy((d) -> d.params?.in_location?[0]?.topic_id)
  # by_entity = _(all_events).groupBy((d) -> d.params?.pkey?[0]?.topic_id)
  # by_articles_count = _(all_events).groupBy((d) -> d.articles.length)


politicians =
  democrat: [10223, 1073, 1082, 11, 11159, 1129, 11442, 11530, 12361, 12377, 13334, 13451, 13766, 14265, 15039, 15171, 15716, 1573, 159757, 16534, 17064, 1846, 18900, 18960, 192, 19441, 19542, 19907, 19935, 20746, 20923, 22036, 225557, 22843, 231280, 231631, 23363, 24955, 24999, 2526, 252681, 255623, 2595, 2599, 2631, 30370, 30706, 31046, 3123, 33080, 3311, 33639, 33708, 34071, 34600, 34804, 34840, 34888, 35268, 3530, 35420, 356, 35616, 3604, 360786, 36747, 36833, 37259, 3747, 3753, 37577, 37947, 38100, 382305, 3829, 3830, 38309, 38459, 388618, 38910, 39091, 391382, 3955, 399798, 40040, 41093, 4165, 42359, 4301, 43578, 4517, 457200, 4601, 470746, 476596, 479326, 5117, 51894, 52075, 545887, 54901, 55263, 5717, 5907, 59911, 61112, 6794, 6878, 7001, 750, 785, 79042, 79739, 81866, 8314, 84853, 8682, 8712, 87915, 8877, 889, 8941, 90098, 9250, 927, 92904, 9320, 963, 9856, 9974]
  neutral: [10037, 10050, 10071, 1012, 10561, 10654, 11082, 11575, 11681, 11740, 11766, 12230, 12237, 1235, 12608, 12684, 13179, 1333, 13519, 1370, 13702, 13793, 13845, 13858, 13949, 14288, 14361, 14447, 15265, 15391, 1561, 15719, 1574, 159790, 160199, 16076, 16098, 161321, 16565, 17000, 17547, 17953, 17971, 18474, 1906, 20403, 20704, 21063, 2124, 2164, 23096, 237436, 237594, 248559, 249546, 252694, 2527, 254143, 255412, 26588, 26863, 27358, 28229, 2828, 28284, 29, 29493, 30152, 30630, 3119, 3126, 31836, 320, 3212, 3250, 32804, 3303, 33054, 33496, 3373, 34751, 34754, 35097, 35322, 360029, 3602, 3610, 36170, 361837, 36272, 36273, 36444, 36532, 36551, 367, 37224, 37225, 3763, 377129, 382510, 386161, 38685, 38911, 3912, 391721, 3923, 39318, 39484, 40048, 4037, 4055, 40777, 4147, 41523, 4177, 4228, 42921, 4357, 4382, 43864, 4401, 44534, 44566, 4527, 4532, 456285, 46569, 477799, 481644, 483052, 5052, 5054, 50547, 5080, 50848, 50849, 51064, 52800, 5364, 5380, 53887, 54465, 54514, 54656, 5644, 5674, 5737, 57891, 5853, 58670, 6076, 6205, 63103, 6556, 65726, 6713, 6718, 70866, 71, 72664, 7428, 74996, 7638, 7839, 7946, 8220, 8221, 850, 8601, 86330, 87, 9097, 9362, 958, 9621, 9784]
  republican: [110, 11253, 1212, 12703, 12736, 12750, 13125, 13139, 1343, 13781, 13913, 14068, 14245, 14672, 14773, 14786, 14793, 15098, 15192, 15338, 15340, 161442, 1689, 16917, 1733, 17891, 18021, 1806, 18658, 18816, 18914, 189511, 19894, 20678, 21082, 2195, 231723, 231773, 2324, 246030, 25011, 2525, 252720, 25361, 2775, 28213, 2825, 28458, 2888, 29855, 3044, 30484, 31172, 31242, 32830, 33197, 34787, 35125, 35203, 3550, 35994, 36049, 36063, 361242, 362455, 38270, 38428, 384762, 39365, 39466, 3957, 3969, 40145, 403, 4118, 4171, 4210, 4508, 4511, 459911, 474198, 479356, 48534, 486489, 490255, 507, 5075, 52531, 527, 53695, 55816, 5847, 5918, 6157, 6168, 6217, 68147, 6853, 69, 694, 698, 699, 8038, 805, 8158, 8253, 83219, 8539, 85924, 90636, 9419, 982775, 9889]
