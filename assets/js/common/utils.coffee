getQuery = (key) ->
    query = window.location.search.substring(1)
    args = query.split('&')
    for arg in args
        pair = arg.split('=')
        if decodeURIComponent(pair[0]) == key
            return decodeURIComponent(pair[1])

    console.log('Query key %s not found', key)

window.utils = getQuery: getQuery
