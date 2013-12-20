app         = (require 'express')()
#backboneio  = require 'backbone.io'
conf        = require "../shared/conf"
server      = (require 'http').createServer app
io          = (require 'socket.io').listen server

platform    = require "hashgo-platform"

# connect the db
require "../shared/models/mongo"

printArt = () ->
  v = conf.get "version"
  console.log "Starting ".yellow + "#{conf.get "app_id"}".green.italic
  console.log """

~                     .`                     .
~                      .`                   .`
~                       .`                 `.
~                        .`                .
~                         .`              .
~                          .`            .`
~                           .`          `.
~                            .`         .
~                             .`       .`
~                              .`     `.
~                               .`    .
~      `.--::::::::://///////////+///+//::::::-`
~      +yhhhhhhhhhhhhhhhhhhhhyhhhhyyhhyyyyyyhdy+
~      sdy/osyssoooo+++++ooooossso+/yh//////+ddo
~      sdy-/s+/                 oo::yh//+o+//dds
~      sdy-/o                    o-:yhoyyo++sdds
~      ody:/s                    s:/hhsyys+oodmy
~      sdy-/o      #{"SidePlay"}    o::hdyhhyossmms
~      sdy:+o     #{"WS Server"}     s::hdssyyo++dds
~      sdy:+o       #{"HashGo"}       s::hdssyyo++dds
~      odh:-s                    o:/hdssssoo+dmy
~      odh/:/o                  o+//hdoo++ohsdds
~      +hddddddddddddddddddhhddddddddddddddddhhs
~      .+osdddddddhhhhhhhhhhhhddhhhhhdhhhhho+++.
~          oNNNNNNNNNNNNNNNNNNNNNNNNNNNNNmo

  """.green



module.exports =
  start: (callback) ->
    # start the server
    server.listen(conf.get("ws:port"))
    # only accept sockets
    app.use (req, res) ->
      if req.secure then protocol = 'https' else protocol = 'http'

      base = "#{protocol}://#{conf.get "base_url"}"
      base += "/#{conf.get "base"}" if conf.get "context"
      
      res.redirect "#{base}"
   
    # socket handler
    # io.sockets.on 'connection', (socket) ->
    #  socket.on ':token', (token) ->
    #    socket.set 'token', token, () ->
    #      socket.emit 'ready'

    ws_router = require "./ws-router"

    io.configure () ->
      io.set 'authorization', ( handshakeData, callback ) ->
        platform.oauth.session.getFromCookies handshakeData.headers.cookie, (error, session) =>
          if error
            callback error
          else if session
            handshakeData.session = session
            callback undefined, true
          else
            callback undefined, false
      
    io.of('/activities').on 'connection', (socket) ->
      ws_router.activities.register socket

    io.of('/user/achievement').on 'connection', (socket) ->
      ws_router.achievements.register socket

    io.of('/events').on 'connection', (socket) ->
      ws_router.events.register socket

    io.of('/predictions').on 'connection', (socket) ->
      ws_router.predictions.register socket

    io.of('/notifications').on 'connection', (socket) ->
      ws_router.notifications.register socket

    # print art and console.log and cb
    printArt()
    console.log "#{conf.get "app_id"} ws server listening on port %d in %s mode" , conf.get("ws:port"), conf.get("NODE_ENV")
    callback() if callback
    
  stop: (callback) ->
    #start server
    app.close () ->
      console.log "#{conf.get "app_id"} app server shutting down"
      callback() if callback

