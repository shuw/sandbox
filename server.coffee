http       = require 'http'
nodeStatic = require 'node-static'
util       = require 'util'

server = http.createServer( (request, response) ->
  response.writeHead 200, 'Content-Type': 'text/plain'
  response.end 'Hello World\n'
).listen 8124

console.log 'Server running at http://127.0.0.1:8124/'


file = new nodeStatic.Server './js'
server = http.createServer( (request, response) ->
  console.log 'asdasd'
  request.addListener 'end', ->
    file.serve request, response, (err, result) ->
     if err
      util.error "Error serving " + request.url + " - " + err.message

      # Respond to the client
      response.writeHead err.status, err.headers
      response.end()

).listen 8125

console.log 'Server running at http://127.0.0.1:8125/'