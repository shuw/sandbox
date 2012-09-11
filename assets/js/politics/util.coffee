
# Groups by key and returns the most frequent items first
window.sort_by_occurrences = (list, key_func, uniq=true) ->
  _(list).chain()
    .groupBy(key_func || ((d) -> d))
    .filter((group, key) -> key != 'undefined')
    .sortBy((group) -> -group.length)
    .map((group) -> if uniq then group[0] else group)
    .value()


window.avatar_creator = (options = {}) ->
  return ->
    @append('img')
      .attr('class', (d) -> d.affiliation || 'unknown')
      .classed('avatar', true)
      .attr('title', (d) -> d.name)
      .attr('src', (d) -> d.image.url)
      .attr('width', (d) -> (options.size || d.image.size)[0])
      .attr('height', (d) -> (options.size || d.image.size)[1])


# First tries to find an image equal or bigger than requested,
# otherwise, settles for a slightly smaller one
window.get_image = (generic_image, width, height) ->
  _images = _.chain(generic_image.sizes).sortBy((i) -> i.size[0])
  image = _images.find((i) -> i.size[0] >= width).value() || _images.last().value()

  if image
    if height
      # scale to fit in box
      width ||= image.size[0]
      height ||= image.size[1]
      scale = Math.min(width / image.size[0], height / image.size[1])
    else
      scale = width / image.size[0]

    image.size = [scale * image.size[0], scale * image.size[1]]

  image
