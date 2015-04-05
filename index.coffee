_ = require 'underscore'
express = require 'express'
request = require 'superagent'
mongojs = require 'mongojs'
debug = require('debug') 'app'
httpProxy = require 'http-proxy'
{ NODE_ENV, ARTSY_URL, PORT, ARTSY_ID, ARTSY_SECRET,
  MONGOHQ_URL, THROTTLE_TIME, PATHS } = process.env
xappToken = 'token'

db = mongojs MONGOHQ_URL, ['cache']
app = express()
proxy = httpProxy.createProxyServer()

# Helper to cache an endpoint
fetchAndCache = (key, url, callback) ->
  request
    .get(ARTSY_URL + url)
    .set('x-xapp-token': xappToken)
    .end (err, sres) ->
      return callback? err if err
      doc =
        key: key
        headers: _.pick(sres.headers, 'content-type', 'content-length', 'etag')
        body: sres.body
      db.cache.update { key: key }, doc, { upsert: true }
      callback? null, doc
debouncedFetchAndCache = _.debounce fetchAndCache, parseInt THROTTLE_TIME

# Cache configured routes
paths = PATHS.split ','
for path in paths
  app.get path, (req, res, next) ->
    key = req.url
    db.cache.findOne { key: key }, (err, cached) ->
      return next err if err
      if cached
        res.set(cached.headers).send cached.body
        debouncedFetchAndCache key, req.url
      else
        fetchAndCache key, req.url, (err, doc) ->
          return next err if err
          res.set(doc.headers).send doc.body

# Proxy the rest of Gravity
app.use (req, res, next) ->
  proxy.web req, res, { target: ARTSY_URL }

# Fetch & hoist an xapp token
request
  .post("#{ARTSY_URL}/api/tokens/xapp_token")
  .send(client_id: ARTSY_ID, client_secret: ARTSY_SECRET)
  .end (err, res) ->
    xappToken = res.body.token
    app.listen PORT, ->
      debug "listening on ", PORT
