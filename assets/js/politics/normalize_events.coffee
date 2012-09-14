NORMALIZE_RELATIONS = {
  'person_runs_political_ad': 'political_ad'
  'organization_runs_political_ad': 'political_ad'
  'person_gave_a_speech': 'speech'
  'person_criticized_person': 'criticism'
  'person_has_polling_numbers': 'polling_numbers'
  'person_holds_campaign_rally': 'campaign_rally'
  'person_raised_campaign_funding': 'campaign_funding'
  'person_holds_fundraiser': 'fundraiser'
  'person_won_party_nomination': 'party_nomination'
  'person_interviewed': 'interviewed'
  'person_arrived_in': 'arrived_in'
}

NORMALIZE_PARAMS = {
  'occurred_at_event': 'for_event'
  'speaker': 'pkey'
}

window.normalize_events = (events) ->
  _(POLITICS_DATA).chain()
    .map((event) ->
      relation_config = NORMALIZE_RELATIONS[event.relation_type]
      return unless relation_config?
      event.date = new Date(event.date)

      affiliations = {}
      normalized_params = {}
      _(event.params).each (params, key) ->
        primary_param = params[0]
        gimage = primary_param.topic_images?[0]
        primary_param.avatar_image = gimage && get_image(gimage, 40, 40) || {
          url: '//wavii-shu.s3.amazonaws.com/images/topic_placeholder.png'
          size: [40, 40]
        }

        if primary_param?.topic_id && affiliation = get_affiliation(primary_param.topic_id)
          primary_param.affiliation = affiliation
          affiliations[affiliation] = true

        normalized_params[NORMALIZE_PARAMS[key] or key] = primary_param


      relation_type = NORMALIZE_RELATIONS[event.relation_type]
      event = _({
        affiliations: _(affiliations).keys()
        params: normalized_params
        media: event.media?[0]
        relation_type: relation_type
      }).defaults(event)

      relation_config = window.relations[event.relation_type]
      if relation_config?.renderable(event)
        event.relation_name = relation_config.friendly_name || "#{_(relation_type).humanize()}s"
        event
      # else
      #   console.debug("Skipping #{event.news_event_id}-#{event.relation_type} because it is not renderable")
    )
    .compact()
    .sortBy((e) -> -e.date)
    .value()
