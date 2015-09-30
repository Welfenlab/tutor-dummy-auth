
session = require 'express-session'

module.exports = (userExists, devUser) ->
  (app, config) ->
    app.use session(
      secret: config.session.secret
      saveUninitialized: true    # FIXME: true? yes/no?
      resave: true               # FIXME: true? yes/no?
      cookie:
        secure: config.ssl.enable
    )

    app.use "/api/login", (req, res) ->
      # dummy auth sets everyone to 123 and accepts only 123
      userExists(req.body.id).then((exists) ->
        if !exists
          console.log "user does not exists #{req.body.id}"
          res.status(401).end()
          return
        req.session.uid = req.body.id
        req.session.save (err) ->
        res.status(204).end())
      .catch((err) ->
        console.error err
        res.status(500).end())

    # affects all app... requests after this one
    # the only accessable thing before logging in is the login form
    app.use "/api", (req, res, next) ->
      if devUser and !req.session.uid?
        req.session.uid = devUser
      if !req.session.uid?
        res.location(config.session.login_redirect)
        next new Error "Please login before accesing the App"
      else
        next()

    app.use "/api/logout", (req, res) ->
      req.session.destroy()
      res.status(204).end()
