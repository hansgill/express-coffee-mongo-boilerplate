_     = require 'underscore'
async = require 'async'

class SocketRegistry

  constructor : (name) ->
    @name = name
    @_prns    = {}
    @_sessions= {}
    @_anon    = []

  register : ( socket, callback ) ->
    ###
    ###
    session = socket.handshake.session
    return callback new Error "No session attached to this socket" unless session or session.session_id
    
    return callback new Error "No Session ID attached to this socket" unless session.session_id
    
    @_addSocketToSessionMap session, socket

    if session.prn
      @_addAuthSocket session, socket
    #else
    #  @_addAnonSocket session, socket

  _addSocketToSessionMap : (session, socket) ->
    # Get session Id and fail if we don't have one.
    sessionId = session.session_id
    return console.error new Error "No Session ID defined for this socket!" unless sessionId
    # Add to Session maps.
    unless @_sessions[sessionId]
      @_sessions[sessionId] = { }

    @_sessions[sessionId][socket.id]  = socket


  _addAuthSocket : (session, socket) ->
    # Get prn and fail if we don't have one.
    prn = session.prn
    return console.error new Error "No PRN defined for this socket!" unless prn
    # init PRN Map if not ready.
    unless @_prns[prn]
      @_prns[prn] = {}
    # Add to PRN maps.
    @_prns[prn][socket.id] = socket


  _addAnonSocket : (session, scoket) ->
    unless _.contains @_anon, socket
      @_anon.push socket


  relay : ( event, message, callback ) ->
    keys = message.hgIds ? message.prns
    if keys and keys?.length isnt 0
      # Check if we have a some Hashgo IDs (hgIds) or Principals (prns)
      @relayToUsers keys, event, message, callback
    # ok, just send the message to all then.
    else
      @relayToAll event, message, callback


  relayToAll  : (event, message, callback) ->

    return callback undefined unless @_sessions

    sessions = _.clone @_sessions

    sids = _.keys sessions

    async.forEach sids, (
      (sid, next) =>
        sockets = sessions[sid]
        for id, socket of sockets
          @_relayToSocket socket, event, message,
            ( (e) ->
              console.error e if e
              console.log "Removing socket for SID #{sid}"
              delete @_sessions[sid][id] if @_sessions[sid][id]
            ),
              ( -> )
    ),
      ( (e) -> )


  relayToUsers : ( prns, event, message, callback ) ->
    unless prns instanceof Array or typeof prns is 'string'
      return callback new Error "PRNs should either be an array or string."

    _prns = if prns instanceof Array then prns else [prns]

    async.forEach _prns, (
      (prn, next) =>
        sockets = _.clone @_prns[prn]
        return next() unless sockets
        for id, socket of sockets
          @_relayToSocket socket, event, message,
            ( (e) ->
              console.log "Removing socket for PRN #{prn} SID #{sid}"
              delete @_prns[prn][id] if @_prns[prn][id]
              console.error e ),
            ( ->
              console.log "#{prn} -> #{id} notified." )
    ),
      ( (e) -> console.error if e )

  _relayToSocket : (socket, event, data, onFail, onSuccess) ->
    try
      socket.emit event, data
      onSuccess() if onSuccess
    catch e
      console.error e
      onFail e if onFail
      
module.exports.SocketRegistry = SocketRegistry
