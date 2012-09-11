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

NORMALIZE_RELATIONS = {
  'person_runs_political_ad': 'political_ad'
  'organization_runs_political_ad': 'political_ad'
  'person_gave_a_speech': 'speech'
}

window.normalize_events = (events) ->
  _(POLITICS_DATA).chain()
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
      e.relation_type = NORMALIZE_RELATIONS[e.relation_type] || e.relation_type
      e
    )
    .sortBy((e) -> -e.date)
    .value()