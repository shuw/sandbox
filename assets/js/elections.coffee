#= require_tree politics

_.mixin(_.string.exports())

# Filter summaries and these relations because we don't handle them well yet...
FILTERED_RELATIONS = _([
  'source_published_article_about_subjects',
  'author_wrote_article_about_subjects',
  'author_from_source_wrote_article_about_subjects',
  'authors_wrote_articles_about_subject',
  'summary',
]).groupBy((k) -> k)

NORMALIZE_PARAMS = {
  'occurred_at_event': 'for_event'
  'speaker': 'pkey'
}

window.elections_init = ->
  # Normalize events and reverse sort by date
  events = _(POLITICS_DATA).chain()
    .reject((e) -> FILTERED_RELATIONS[e.relation_type]?)
    .map((e) ->
      e.date = new Date(e.date)

      affiliations = {}
      normalized_params = {}
      _(e.params).each (params, key) ->
        primary_param = params[0]
        if primary_param?.topic_id && affiliation = get_affiliation(primary_param.topic_id)
          primary_param.affiliation = affiliation
          affiliations[affiliation] = true

        normalized_params[NORMALIZE_PARAMS[key] or key] = primary_param

      e.affiliations = _(affiliations).keys()
      e.params = normalized_params
      e.relation_type = NORMALIZE_PARAMS[e.relation_type] || e.relation_type
      e
    )
    .sortBy((e) -> -e.date)
    .value()

  init_filters(events, (selected) ->
    d3.selectAll('#root')
      .data([selected])
      .each(draw_groups)
      .each(draw_raw_data)
  )

