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
      debugger
      {
        team: events[0].team
        count: events.length
        grouped_awards: [awards['Gold Medal'] || [], awards['Silver Medal'] || [], awards['Bronze Medal'] || []]
      })
    .sortBy((d) -> -d.count)
    .value()

  update_selected = (selected_el) -> $('#scoreboard .link').each (x) -> $(@).toggleClass('selected', @ == selected_el)

  all_events = _(g_relations).flatten()
  scoreboard = d3.select('#scoreboard')
  scoreboard
    .append('div')
    .classed('all link selected', true)
    .text((d) -> "All Events")
    .on 'click', ->
      update_selected @
      show_events all_events

  teams = scoreboard.selectAll('.team').data(by_team, (d) -> d.team.id)
  teams.enter()
    .append('div')
    .classed('team', true)
    .call(->
      @append('img')
        .attr('src', (d) -> d.team.image?.sizes[0].url)
        .on 'click', (d) ->
          update_selected @
          show_events _(d.grouped_awards).flatten()
      @append('span').classed('name link', true)
        .text((d) -> d.team.label)
        .on 'click', (d) ->
          update_selected @
          show_events _(d.grouped_awards).flatten()
      @append('span').classed('awards', true)
        .selectAll('.award')
        .data((d) -> d.grouped_awards)
        .enter()
          .append('span').classed('award link', true)
          .text((d) -> d.length)
          .on('click', (awards) ->
            update_selected @
            show_events awards
            d3.event.stopPropagation()
          )
    )

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
    organization_wins_award:              { team: 'left_pkey', award: 'right_pkey', event: 'in_event' }
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
    person_suspected_of_cheating:         { team: 'for__organization', person: 'pkey', event: 'in_event' }
  }).reduce(((rels, mappings, relation_type) ->
    rels[relation_type] = _news_events
      .filter((n) -> n.relation_type == relation_type)
      .map((n) ->
        event =
          date: new Date(n.date)
          images: n.images || []
          headline: n.headline
          id: n.news_event_id

        _(mappings).reduce(((event, param_key, normalized_key) ->
          p = n.params[param_key]?[0]
          if p
            event[normalized_key] =
              id:    p.topic_id
              label: TEAM_TOPICS_ABBREVIATED[p.topic_id] || p.topic.name
              image: p.topic_images?[0]
          else
            console.warn "NewsEvent #{relation_type} missing #{param_key}"
          event
        ), event)

        if event.event
          event
        else
          console.warn "NewsEvent #{n.news_event_id} does not have a event param"

      ).compact().value()
    rels
  ), {})

  # normalize relations
  normalized_relations = _({
    awards: ['person_wins_event', 'organization_wins_award']
    advancements: ['person_advances_in_event', 'organization_advances_in_event']
    olympic_records: ['organization_sets_olympic_record', 'person_sets_olympic_record']
    world_records: ['organization_sets_world_record', 'person_sets_world_record']
    eliminations: ['person_eliminated_from_event', 'organization_eliminated_from_event']
    disqualifications: ['person_disqualified_from_event', 'organization_disqualified_from_event']
    injuries: ['person_injured_at_event']
    cheating: ['person_suspected_of_cheating']
  }).reduce(((normalized_rels, relation_types, normalized_relation_type) ->
    normalized_rels[normalized_relation_type] = _(relation_types).chain().map((r) -> rels[r] || []).flatten().value()
    normalized_rels
  ), {})

  # aggregated events (i.e. Men's 100) with individual events (i.e. Gold Medal Men's 100, Silver Medal Men's 100, etc)
  agg_events = _(normalized_relations).reduce(((result, events, relation_type) ->
    _(events).each (e) ->
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


# Constants

window.TEAM_TOPICS_ABBREVIATED = { 'yVVkq': 'ETH', 'y4a98': 'AFG', 'ynT8m': 'ALB', 'yTRCJ': 'DZA', 'yVYWr': 'ASM', 'yADqp': 'AND', 'y5PfN': 'AGO', 'ykN9P': 'ATG', 'ycg33': 'ARG', 'yBhaK': 'ARM', 'y9f7k': 'ABW', 'ym6dW': 'AUS', 'yNx7L': 'AUT', 'ySwpd': 'AZE', 'yHdQx': 'BHR', 'yUtfu': 'BGD', 'ysQF9': 'BRB', 'yUBxc': 'BLR', 'yJK9C': 'BEL', 'yJkKG': 'BEN', 'yjw8Y': 'BMU', 'yjJRF': 'BTN', 'yCmHs': 'BOL', 'y76RU': 'BWA', 'yDhAh': 'BRA', 'yerKg': 'VGB', 'ycDps': 'BGR', 'yBnnB': 'BDI', 'y9H8E': 'KHM', 'ym7C2': 'CMR', 'yxvqn': 'CAN', 'y7mqd': 'CPV', 'yDsfe': 'CYM', 'yHkut': 'CAF', 'yeF9x': 'TCD', 'ysCNM': 'CHL', 'yPE3a': 'CHN', 'yN37f': 'COL', 'ymSdF': 'COM', 'ynQ7y': 'COK', 'yCVLq': 'CRI', 'yVTh7': 'HRV', 'ysAFk': 'CUB', 'yPMxA': 'CYP', 'y4XEN': 'CZE', 'yVAyy': 'DNK', 'yA4gq': 'DJI', 'y5WAv': 'DMA', 'yARjH': 'DOM', 'y5FQb': 'ECU', 'yPVxT': 'EGY', 'y4PEe': 'SLV', 'ynYRQ': 'GNQ', 'yT5Hd': 'ERI', 'yYjGJ': 'FJI', 'yWBgA': 'FIN', 'yvJdr': 'FRA', 'yCqT3': 'GAB', 'yBygc': 'DEU', 'yxjn3': 'GHA', 'yc2pn': 'GRC', 'y9L8M': 'GRD', 'yBEnD': 'GUM', 'ym8CR': 'GTM', 'yYSWU': 'GIN', 'yWUqV': 'GUY', 'yNcug': 'HTI', 'yvHNm': 'HND', 'yUa3B': 'HKG', 'yJpaj': 'HUN', 'yjuj2': 'ISL', 'yyLhm': 'IND', 'y78jJ': 'IDN', 'yDKQ8': 'IRN', 'ye3FL': 'IRQ', 'yBsEu': 'ISR', 'y9eu5': 'ITA', 'ymTNY': 'JAM', 'ySRGR': 'JPN', 'yxMgT': 'JOR', 'yHpAS': 'KAZ', 'ysbdQ': 'KEN', 'yUUfw': 'KWT', 'yJ99b': 'KGZ', 'yj587': 'LVA', 'yCjCH': 'LBN', 'yVbWF': 'LSO', 'yA2qs': 'LBR', 'y5XuG': 'LBY', 'ykdNE': 'LIE', 'yPn3X': 'LTU', 'y4Wah': 'LUX', 'ynA79': 'MKD', 'yT4dU': 'MWI', 'yYmpp': 'MYS', 'yWgna': 'MDV', 'yNCQP': 'MLI', 'yvuFy': 'MLT', 'yDyAK': 'MEX', 'y7SRW': 'MDA', 'yFDHn': 'MNG', 'yySJ7': 'MNE', 'y7U3H': 'MAR', 'yDchb': 'MOZ', 'yeHjf': 'MMR', 'yYgVT': 'NAM', 'yWpue': 'NRU', 'yNuxQ': 'NPL', 'yvMEd': 'NLD', 'yV26J': 'NZL', 'yAEAA': 'NIC', 'y5LGL': 'NER', 'yPWBu': 'NGA', 'y4e8C': 'PRK', 'yn4pY': 'NOR', 'yTv93': 'OMN', 'yy8SW': 'PAK', 'yAyfn': 'PLW', 'ykSqM': 'PAN', 'ycsMa': 'PNG', 'yBF7v': 'PRY', 'y9mGy': 'PER', 'ymgaq': 'PHL', 'ySM4s': 'POL', 'yxXQB': 'PRT', 'yHbpE': 'PRI', 'yU9yh': 'QAT', 'yJARg': 'ROU', 'yjjxU': 'RUS', 'yCWEV': 'RWA', 'y7gA6': 'LCA', 'yeuR5': 'WSM', 'ycy4V': 'SMR', 'yBc88': 'SAU', 'y9Spm': 'SEN', 'ymDnJ': 'SRB', 'ySjVq': 'SYC', 'yxWuw': 'SLE', 'yHAW4': 'SGP', 'ys4q7': 'SVK', 'yPXMD': 'SVN', 'y4d7S': 'ZAF', 'yn23R': 'KOR', 'yTEaT': 'ESP', 'yV44d': 'LKA', 'yAsQX': 'SDN', 'y5ehx': 'SUR', 'ykTj9': 'SWE', 'ycEVc': 'CHE', 'yB3RG': 'SYR', 'y98xF': 'TJK', 'yTyEs': 'TZA', 'yN5Gk': 'THA', 'yYUM3': 'TGO', 'yW97K': 'TON', 'yvjgW': 'TTO', 'yUpBN': 'TUN', 'yJb8P': 'TUR', 'yjMfp': 'TKM', 'yCt9a': 'UGA', 'yy7SF': 'UKR', 'y7Bfs': 'ARE', 'yDxWG': 'URY', 'yeJqE': 'UZB', 'yYtMX': 'VUT', 'yWK7h': 'VEN', 'yNwG9': 'VNM', 'ySV4p': 'YEM', 'yxPQa': 'ZMB', 'yHYhP': 'ZWE', 'ys5jy': 'BFA', 'y4SGs': 'USA' }

window.MEDAL_IMAGES =
  'yC4gq': 'https://wavii-images.s3.amazonaws.com/topic/c3Sk/a84eecf2fd37622db40425f19b72ceb1/orig.jpg' # gold
  'yBQ2g': 'https://wavii-images.s3.amazonaws.com/topic/sScC/134c2bb983a7cb8d678040e748168c2b/orig.jpg' # silver
  'yF5Fy': 'https://wavii-images.s3.amazonaws.com/topic/DYur/1dbaee944cd80e346afc503d2920e876/orig.jpg' # bronze
