# Author: Shu Wu
#
# TODO: Calculate inverse document frequency offline using larger corpus


#= require vendor/d3.layout.cloud

width = 1400
height = 800

# word count
tf = {}
# document frequency hash (also maps word -> news events)
df = {}

_.mixin(_.string.exports())

skip_topic_names = false

window.words_init = (data_path, test_mode=false) ->
  d3.json data_path, (news) ->
    stop_words_dict = {}
    _(stop_words).each (w) -> stop_words_dict[w] = 1

    if skip_topic_names
      _(news).each (n) ->
        topics = (if n.summary then _.chain(n.summary.entities) else _.chain(n.params).flatten())
        topics
          .each (t) -> _.chain(t.topic?.name? && t.topic.name).words().each((w) -> stop_words_dict[w.toLowerCase()] = 1)

    # we should really be using a more general IDF index calculated over many weeks of news
    # but this is just a prototype so...
    _(news).each (n) ->
      _words =  _.chain(n)
        .words()
        .map((w) -> _(w.toLowerCase()).strip().replace(/[^\w\s]|_/g, '').split("'")[0])
        .uniq()
        .filter((w) ->
          /^\w+$/.test(w) &&
          w.length > 4 &&
          w.indexOf('facebook') == -1 &&
          !stop_words_dict[w]
        )

      _words.uniq().each (w) ->
        w_lower = w.toLowerCase()
        df[w_lower] ||= []
        # we can add news events more than once
        df[w_lower].push(n)
      _words.each (w) -> tf[w] = (tf[w] || 0) + 1

    top_words = _.chain(tf)
      .map((count, w) -> { word: w, size: Math.sqrt(count)  })
      .sortBy((d) -> d.size)
      .reverse()
      .first(250)
      .value()

    _dates = _.chain(news).map((n) -> moment(n.date))
    $('#description > .date_range').text "from " + _dates.min().value().fromNow() + ' - ' + _dates.max().value().fromNow()

    debounced_layout = _.debounce (-> layout(top_words)), 4000
    $('#root')
      .attr("width", width)
      .attr("height", height)
      .mousemove(debounced_layout) # will cancel layout redraw for 4 seconds

    # setInterval(debounced_layout, 15000)
    layout(top_words)


# based on https://github.com/jasondavies/d3-cloud/blob/master/examples/simple.html
layout = (weighted_words) ->
  return unless weighted_words.length > 2
  font_size = d3.scale
    .linear()
    .range([10, 100])
    .domain([_(weighted_words).last().size, _(weighted_words).first().size])
  d3.layout.cloud()
    .timeInterval(10)
    .size([width, height])
    .text((d) -> d.word)
    .spiral('archimedean')
    .font("Impact")
    .fontSize((d) -> font_size(d.size))
    .rotate((d) -> ~~(Math.random() * 5) * 30 - 60)
    .padding(20)
    .words(weighted_words)
    .on("end", draw)
    .start()


paused = false
unpause_debounced = _.debounce((-> pause = false), 5000)
draw = (words) ->
  color = d3.scale.category10()
  text = d3.select("#root g")
    .attr("transform", "translate(#{width/2},#{height/2})")
    .selectAll("text")
    .data(words, (w) -> w.text)
  text.transition().duration(1000)
    .style("font-size", (d) -> "#{d.size}px")
    .attr("transform", (d) -> "translate(#{[d.x, d.y]})rotate(#{d.rotate})")
  text.enter().append("text")
    .style("font-size", (d) -> "#{d.size}px")
    .style("cursor", 'pointer')
    .attr("transform", (d) -> "translate(#{[d.x, d.y]})rotate(#{d.rotate})")
    .style("font-family", 'Impact')
    .attr("text-anchor", "middle")
    .style("fill", (d) -> color(d.text))
    .text((d) -> d.text)
    .style("opacity", 0).transition().duration(1000).style("opacity", 1)
  text.on 'mouseover', (data) -> show_news(data.text) unless paused
  text.on 'click', (data) ->
    $("html, body").animate({ scrollTop: $(document).height() }, 1000);
    show_news(data.text, true)
    paused = true
    unpause_debounced()
  text.exit().remove()


show_news = (word, highlight=false) ->
  news = d3.select('#news')
    .selectAll('.headline')
    .data(df[word.toLowerCase()], (d) -> d.news_event_id)

  news.enter().append('a')
    .classed('headline', true)
    .attr('target', '_blank')
    .attr('href', (d) -> "https://wavii.com/news/#{d.news_event_id}")
    .text((d) -> d.headline)

  news.exit().remove()

  news.classed('highlight', highlight)


# from http://www.ranks.nl/resources/stopwords.html
stop_words = ["112845672063384274mark", "httpfacebookcomlookback", "made", "httpsfacebookcomlookback", "a","about","above","after","again","against","all","am","an","and","any","are","aren't","as","at","be","because","been","before","being","below","between","both","but","by","can't","cannot","could","couldn't","did","didn't","do","does","doesn't","doing","don't","down","during","each","few","for","from","further","had","hadn't","has","hasn't","have","haven't","having","he","he'd","he'll","he's","her","here","here's","hers","herself","him","himself","his","how","how's","i","i'd","i'll","i'm","i've","if","in","into","is","isn't","it","it's","its","itself","let's","me","more","most","mustn't","my","myself","no","nor","not","of","off","on","once","only","or","other","ought","our","ours ","ourselves","out","over","own","same","shan't","she","she'd","she'll","she's","should","shouldn't","so","some","such","than","that","that's","the","their","theirs","them","themselves","then","there","there's","these","they","they'd","they'll","they're","they've","this","those","through","to","too","under","until","up","very","was","wasn't","we","we'd","we'll","we're","we've","were","weren't","what","what's","when","when's","where","where's","which","while","who","who's","whom","why","why's","with","won't","would","wouldn't","you","you'd","you'll","you're","you've","your","yours","yourself","yourselves", "facebook", "facebookis10", "find", "movie","httpsfacebookcomlookback", "heres"]
