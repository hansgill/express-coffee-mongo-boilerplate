_     = require 'underscore'
async = require 'async'

{ Achievement } = require "../shared/models/achievement"
{ Notification } = require "../shared/models/notification"
{ Activity } = require "../shared/models/activity"
{ Event, EventAiringState } = require "../shared/models/event"
{ Prediction } = require "../shared/models/prediction"
{ Cast } = require "../shared/models/cast"

{SocketRegistry} = require "./socket-registry"

socketRegistry =
  activities    : new SocketRegistry "activities"
  achievements  : new SocketRegistry "achievements"
  events        : new SocketRegistry "events"
  predictions   : new SocketRegistry "predictions"
  notifications : new SocketRegistry "notifications"


### Activities ###
_sendActivity = (activity) ->
  return unless activity
  message = _.clone activity
  message.hgIds = activity.userAudience if activity.userAudience
  socketRegistry.activities.relay "create", message

Activity.onContextEvent activityType, _sendActivity for activityType in [
  "comment:created"
  "episode_airing:announce"
  "event_airing:published"
  "event_airing:locked"
  "event_airing:closed"
  "event_airing:removed"
  "prediction:made"
  "score-event-group:closed"
]



### Notifications ###
_sendNotification = (notification) ->
  return unless notification
  message = _.clone notification
  message.hgIds = notification.hgId
  socketRegistry.notifications.relay "create", message

Notification.onContextEvent notificationType, _sendNotification for notificationType in [
  "gameinvite:created"
  "gameinvite:accepted"
]



### Achievments ###

###  Event Airings ###
_pushEventAiringUpdate = (eas, type) ->
  #add the outcome detail if there is an outcome
  if eas.event.outcome?.length > 0
    Cast.findOne {_id:eas.event.outcome[0]}, (err,cast)->
      eas.event.outcome[0] = cast
      socketRegistry.events.relay type, eas
  else
    socketRegistry.events.relay type, eas

EventAiringState.onContextEvent ":published", (airingState) -> _pushEventAiringUpdate airingState, "published"

EventAiringState.onContextEvent ":locked",    (airingState) -> _pushEventAiringUpdate airingState, "locked"

EventAiringState.onContextEvent ":closed",    (airingState) -> _pushEventAiringUpdate airingState, "closed"

EventAiringState.onContextEvent ":unlocked",    (airingState) -> _pushEventAiringUpdate airingState, "unlocked"


### Predictions ###
_predictionEventHandler = (event) -> (doc) ->
  message = _.clone doc
  message.hgIds = doc.user.hgId
  Cast.findOne {_id:doc.prediction[0]}, (err,cast)->
    doc.prediction[0] = cast
    socketRegistry.predictions.relay event, message

Prediction.onContextEvent ":created", _predictionEventHandler "created"
Prediction.onContextEvent ":updated", _predictionEventHandler "updated"
Prediction.onContextEvent ":closed" , _predictionEventHandler "closed"


module.exports =
  activities:
    register: (socket) ->
      socketRegistry.activities.register socket, ( (e) -> )

  achievements:
    register: (socket) ->
      socketRegistry.achievements.register socket, ( (e) -> )
    
  events:
    register: (socket) ->
      socketRegistry.events.register socket, ( (e) -> )

  predictions:
    register: (socket) ->
      socketRegistry.predictions.register socket, ( (e) -> )

  notifications:
    register: (socket) ->
      socketRegistry.notifications.register socket, ( (e) -> )
