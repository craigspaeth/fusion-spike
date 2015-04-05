require 'newrelic'
_ = require 'underscore'
express = require 'express'
request = require 'superagent'
mongojs = require 'mongojs'
debug = require('debug') 'app'
httpProxy = require 'http-proxy'
cors = require 'cors'
{ NODE_ENV, ARTSY_URL, PORT, ARTSY_ID, ARTSY_SECRET,
  MONGOHQ_URL, THROTTLE_TIME, PATHS } = process.env
xappToken = 'token'

db = mongojs MONGOHQ_URL, ['cache']
app = express()
proxy = httpProxy.createProxyServer()

# Helper to cache an endpoint
fetchAndCache = (key, url, callback) ->
  debug "Fetching: " + key
  request
    .get(ARTSY_URL + url)
    .set('x-xapp-token': xappToken)
    .end (err, sres) ->
      return callback? err if err
      doc =
        _id: key
        headers: _.pick(sres.headers, 'content-type', 'content-length', 'etag')
        body: sres.body
      db.cache.update { _id: key }, doc, { upsert: true }
      callback? null, doc

# CORS support
app.use cors()

# Cache configured routes
debounced = {}
paths = PATHS.split ','
for path in paths
  app.get path, (req, res, next) ->
    key = req.url
    db.cache.findOne { _id: key }, (err, cached) ->
      return next err if err
      if cached
        res.set(cached.headers).send cached.body
        debounced[key] ?= _.debounce(
          (-> fetchAndCache key, req.url)
          parseInt(THROTTLE_TIME)
        )
        debounced[key]()
      else
        fetchAndCache key, req.url, (err, doc) ->
          return next err if err
          res.set(doc.headers).send doc.body

# Proxy the rest of Gravity
app.use (req, res, next) ->
  proxy.web req, res, { target: ARTSY_URL }

# Display similar errors
app.use (err, req, res, next) ->
  if err.status
    body = if _.isEmpty(b = err.response.body) then err.response.text else b
    res.status(err.status).send(body)
  else
    next err

# Fetch & hoist an xapp token
request
  .post("#{ARTSY_URL}/api/tokens/xapp_token")
  .send(client_id: ARTSY_ID, client_secret: ARTSY_SECRET)
  .end (err, res) ->
    xappToken = res.body.token
    app.listen PORT, ->
      debug "listening on ", PORT
