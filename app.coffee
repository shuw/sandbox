connect = require 'connect'
express = require 'express'
jade = require 'jade'

app = module.exports = express.createServer()

# CONFIGURATION

app.configure(() ->
	app.set 'view engine', 'jade'
	app.set 'views', "#{__dirname}/views"

	pub_dir = __dirname + '/public'
	app.use require('connect-assets')()
	app.use connect.bodyParser()
	app.use connect.static(pub_dir)
	app.use express.cookieParser()
	app.use express.session({secret : "shhhhhhhhhhhhhh!"})
	app.use express.logger()
	app.use express.methodOverride()
	app.use app.router
)

app.configure 'development', () ->
	app.use express.errorHandler({
		dumpExceptions: true
		showStack     : true
	})

app.configure 'production', () ->
	app.use express.errorHandler()

# ROUTES

app.get '/', (req, res) ->
	res.render 'index',
	locals:
		title:			'Experiments'

app.post '/trailer/create', (req, res) ->
  exec = require('child_process').exec
  child = exec(
    "scripts/generate.sh #{req.body.user}",
    (error, stdout, stderr) ->
      console.log('stdout: ' + stdout)
    )
  res.json('scheduled')

app.get '/topic_graph', (req, res) ->
	res.render 'topic_graph',
		locals:
			data_path:	req.query["data"] || 'celebrities_started_dating'
			title:			'/|/|/'

app.get '/:experiment_name', (req, res) ->
	experiment_name = req.params.experiment_name
	res.render experiment_name,
		locals:
			title: experiment_name.replace('_', ' ')

app.listen(8090)
console.log "Express server listening on port #{app.address().port}"
