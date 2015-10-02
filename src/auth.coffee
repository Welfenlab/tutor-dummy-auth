
session = require 'express-session'

module.exports = (userLogin) ->
  (app, config) ->
    app.use session(
      secret: config.session.secret
      saveUninitialized: true    # FIXME: true? yes/no?
      resave: true               # FIXME: true? yes/no?
      cookie:
        secure: config.ssl.enable
    )

    app.use "/api/login", (req, res) ->
      userLogin(req.body.id, req.body.password).then((correct) ->
        if !correct
          console.log "Wrong user credentials for #{req.body.id}"
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
      if !req.session.uid?
        res.location(config.session.login_redirect)
        next new Error "Please login before accesing the App"
      else
        next()

    app.use "/api/logout", (req, res) ->
      req.session.destroy()
      res.status(204).end()
