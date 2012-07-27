_.mixin(_.string.exports())

g_relations = {}
g_stream = null

window.olympics_init = (data_path) ->
  g_stream = new OlympicStream '#stream'

  $.ajax data_path, success: (events) ->
    g_relations = normalize_relations(events)
    update_scoreboard()
    show_events _(g_relations).chain().map((events) -> events).flatten().value()


update_scoreboard = ->
  by_team = _(g_relations['awards']).chain()
    .groupBy((d) -> d.team.label)
    .map((events) ->
      awards = _(events).groupBy((d) -> d.award.label)
      {
        team: events[0].team
        count: events.length
        grouped_awards: [awards['Gold Medal'] || [], awards['Silver Medal'] || [], awards['Bronze Medal'] || []]
      })
    .sortBy((d) -> -d.count)
    .value()

  teams = d3.select('#scoreboard').selectAll('.team')
    .data(by_team, (d) -> d.team.id)
  teams.enter()
    .append('div')
    .classed('team link', true)
    .call(->
      @append('img')
        .attr('src', (d) -> d.team.image?.sizes[0].url)
        .attr('height', 30)
        .attr('width', 30)
      @append('span').classed('name', true)
        .text((d) -> d.team.label)
      @append('span').classed('awards', true)
        .selectAll('.award')
        .data((d) -> d.grouped_awards)
        .enter()
          .append('span').classed('award link', true)
          .text((d) -> d.length)
          .on('click', (awards) ->
            show_events(awards)
            d3.event.stopPropagation()
          )
    )
    .on 'click', (d) ->
      show_events _(d.grouped_awards).flatten()

  teams.exit().remove()


show_events = (events) ->
  agg_events = _(events).chain().map((e) -> e.agg_event).uniq().value()
  g_stream.update agg_events


# returns { normalized_relations -> event_wrappers[] }
normalize_relations = (news_events) ->
  _news_events = _(news_events).chain()

  # normalize events
  rels = _({
    person_wins_event:                    { team: 'for__organization', person: 'left_pkey', award: 'the_award', event: 'right_pkey' }
    for:              { team: 'left_pkey', award: 'right_pkey' }
    person_advances_in_event:             { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    organization_advances_in_event:       { team: 'left_pkey', event: 'right_pkey' }
    person_sets_olympic_record:           { team: 'for__organization', person: 'pkey', event: 'in_event' }
    person_sets_world_record:             { team: 'for__organization', person: 'pkey', event: 'in_event' }
    organization_sets_olympic_record:     { team: 'pkey', event: 'in_event' }
    organization_sets_world_record:       { team: 'pkey', event: 'in_event' }
    person_disqualified_from_event:       { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    organization_disqualified_from_event: { team: 'left_pkey', event: 'right_pkey' }
    person_eliminated_from_event:         { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    organization_eliminated_from_event:   { team: 'left_pkey', event: 'right_pkey' }
    person_injured_at_event:              { team: 'for__organization', person: 'left_pkey', event: 'right_pkey' }
    person_suspected_of_cheating:         { team: 'for__organization', person: 'pkey' }
  }).reduce(((rels, mappings, relation_type) ->
    rels[relation_type] = _news_events
      .filter((n) -> n.relation_type == relation_type)
      .map((n) ->
        event = date: new Date(n.date)
        _(mappings).reduce(((event, param_key, normalized_key) ->
          p = n.params[param_key]?[0]
          if p
            event[normalized_key] =
              id:    p.topic_id
              label: ENTITY_ABBREVIATED[p.topic_id] || p.label
              image: p.topic_images?[0]
          else
            console.warn "#{relation_type} missing #{param_key}"
          event
        ), event)
      ).value()
    rels
  ), {})

  # normalize relations
  normalized_relations = _({
    awards: ['person_wins_event', 'organization_wins_award']
    advancements: ['person_advances_in_event', 'organization_advances_in_event']
    olympic_records: ['organization_sets_olympic_record', 'person_sets_olympic_record']
    world_records: ['organization_sets_world_record', 'person_sets_world_record']
  }).reduce(((normalized_rels, relation_types, normalized_relation_type) ->
    normalized_rels[normalized_relation_type] = _(relation_types).chain().map((r) -> rels[r] || []).flatten().value()
    normalized_rels
  ), {})

  # aggregated events (i.e. Men's 100) with individual events (i.e. Gold Medal Men's 100, Silver Medal Men's 100, etc)
  agg_events = _(normalized_relations).reduce(((result, events, relation_type) ->
    _(events).each (e) ->
      if e.event
        agg_event = result[e.event.id] ||= {
          id: e.event.id
          image: e.event.image
          label: e.event.label
          rels: {}         # i.e. awards, advancements, world_records
        }
        agg_event.rels[relation_type] ||= []
        agg_event.rels[relation_type].push(e)
    result
  ), {})


  # assign dates to aggregated events
  _(agg_events).each (agg) ->
    agg.date = _(agg.rels).chain().flatten().map((e) -> e.date).max().value()

  # now saturate events with aggregated events
  _(normalized_relations).chain().flatten().each (e) -> e.agg_event = agg_events[e.event.id]

  normalized_relations




ENTITY_ABBREVIATED = { 567952: 'ETH', 595341: 'AFG', 595342: 'ALB', 595343: 'DZA', 595344: 'ASM', 595345: 'AND', 595346: 'AGO', 595347: 'ATG', 595348: 'ARG', 595349: 'ARM', 595350: 'ABW', 595351: 'AUS', 595386: 'AUT', 595352: 'AZE', 595354: 'BHR', 595388: 'BGD', 595355: 'BRB', 595356: 'BLR', 595389: 'BEL', 595357: 'BEN', 595390: 'BMU', 595358: 'BTN', 595359: 'BOL', 595361: 'BWA', 595362: 'BRA', 595363: 'VGB', 595364: 'BGR', 595365: 'BDI', 595366: 'KHM', 595367: 'CMR', 595369: 'CAN', 595393: 'CPV', 595394: 'CYM', 595370: 'CAF', 595395: 'TCD', 595371: 'CHL', 595372: 'CHN', 595398: 'COL', 595399: 'COM', 595374: 'COK', 595375: 'CRI', 595376: 'HRV', 595403: 'CUB', 595404: 'CYP', 595405: 'CZE', 595408: 'DNK', 595409: 'DJI', 595410: 'DMA', 595377: 'DOM', 595378: 'ECU', 595380: 'EGY', 595381: 'SLV', 595382: 'GNQ', 595383: 'ERI', 595384: 'FJI', 595385: 'FIN', 595387: 'FRA', 595391: 'GAB', 595397: 'DEU', 595401: 'GHA', 595412: 'GRC', 595414: 'GRD', 595413: 'GUM', 595415: 'GTM', 595416: 'GIN', 595417: 'GUY', 595418: 'HTI', 595419: 'HND', 595420: 'HKG', 595421: 'HUN', 595422: 'ISL', 595424: 'IND', 595425: 'IDN', 595426: 'IRN', 595427: 'IRQ', 595429: 'ISR', 595430: 'ITA', 595431: 'JAM', 595432: 'JPN', 595433: 'JOR', 595434: 'KAZ', 595435: 'KEN', 595436: 'KWT', 595437: 'KGZ', 595438: 'LVA', 595439: 'LBN', 595440: 'LSO', 595441: 'LBR', 595442: 'LBY', 595443: 'LIE', 595444: 'LTU', 595445: 'LUX', 595446: 'MKD', 595447: 'MWI', 595448: 'MYS', 595449: 'MDV', 595450: 'MLI', 595451: 'MLT', 595452: 'MEX', 595454: 'MDA', 595455: 'MNG', 595456: 'MNE', 595457: 'MAR', 595458: 'MOZ', 595459: 'MMR', 595460: 'NAM', 595461: 'NRU', 595462: 'NPL', 595463: 'NLD', 595464: 'NZL', 595465: 'NIC', 595466: 'NER', 595468: 'NGA', 595469: 'PRK', 595470: 'NOR', 595471: 'OMN', 595472: 'PAK', 595473: 'PLW', 595475: 'PAN', 595476: 'PNG', 595477: 'PRY', 595478: 'PER', 595479: 'PHL', 595480: 'POL', 595481: 'PRT', 595482: 'PRI', 595484: 'QAT', 595485: 'ROU', 595486: 'RUS', 595487: 'RWA', 595489: 'LCA', 595491: 'WSM', 595492: 'SMR', 595493: 'SAU', 595494: 'SEN', 595495: 'SRB', 595496: 'SYC', 595497: 'SLE', 595498: 'SGP', 595499: 'SVK', 595500: 'SVN', 595501: 'ZAF', 595502: 'KOR', 595503: 'ESP', 595504: 'LKA', 595505: 'SDN', 595506: 'SUR', 595507: 'SWE', 595508: 'CHE', 595509: 'SYR', 595510: 'TJK', 595511: 'TZA', 595514: 'THA', 595512: 'TGO', 595513: 'TON', 595515: 'TTO', 595516: 'TUN', 595517: 'TUR', 595518: 'TKM', 595519: 'UGA', 595520: 'UKR', 595521: 'ARE', 595522: 'URY', 595523: 'UZB', 595524: 'VUT', 595525: 'VEN', 595526: 'VNM', 595528: 'YEM', 595529: 'ZMB', 595530: 'ZWE', 595531: 'BFA', 562357: 'USA' }