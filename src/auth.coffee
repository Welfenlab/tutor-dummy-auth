
session = require 'express-session'

module.exports = (userPseudonym, devUser) ->
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
      userPseudonym(req.body.id).then((pseudonym) ->
        req.session.pseudonym = pseudonym
        console.log "api login", req.session
        req.session.save (err) ->
        res.status(204).end())
        .catch((err) -> 
          res.status(401).end()
        )

    # affects all app... requests after this one
    # the only accessable thing before logging in is the login form
    app.use "/api", (req, res, next) ->
      if devUser and !req.session.pseudonym?
        req.session.pseudonym = devUser
      if !req.session.pseudonym?
        res.location(config.session.login_redirect)
        next new Error "Please login before accesing the App"
      else
        next()

    app.use "/api/logout", (req, res) ->
      req.session.destroy()
      res.status(204).end()
