_       = require 'underscore'

should  = require 'should'
sinon   = require 'sinon'
uuid    = require 'node-uuid'

async   = require 'async'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../../lib/shared/models/mongo"

{Event}       = require '../../../../lib/shared/models/event'
{Prediction}  = require '../../../../lib/shared/models/prediction'
{Profile}     = require '../../../../lib/shared/models/user/user-profile'
{ScoreEvent, ScoreEventGroup} = require '../../../../lib/shared/models/score/score-event'

class ScoreEventGroupFixtures

  TEST_NAME = "score-event-group"

  init : ( callback ) ->

    context =
      uuid : uuid.v1()

    async.series [
      ( next ) => @_initUserProfiles context, next
      ( next ) => @_initEvent context, next
      ( next ) => @_initPredictions context, next
      ( next ) => @_initScoreEventGroup context, next
    ], ( error, results ) =>
      callback error, context

  _initUserProfiles: (context, callback) =>

    uuid = context.uuid

    _newProfile = ( name ) =>
      data =
        user:
          session: "#{name}-session-#{uuid}"
          hgId: "#{name}-#{uuid}@#{TEST_NAME}-test"
        timezone: -7
      new Profile data
    
    [smarty, loosey, cranky, curly, larry, moe] = _users = [
      "smarty"
      "loosey"
      "cranky"
      "curly"
      "larry"
      "moe"
    ].map (n) -> _newProfile n

    smarty.friend  =  [loosey, cranky, curly, larry, moe].map (e) -> e.user.hgId
    
    loosey.friend  =  [smarty, cranky, curly, larry, moe].map (e) -> e.user.hgId
    
    cranky.friend  =  [smarty, loosey, curly, larry, moe].map (e) -> e.user.hgId

    context.users =
      smarty :
        profile : smarty
      loosey :
        profile : loosey
      cranky :
        profile : cranky
      stooges:
        curly : curly
        larry : larry
        moe   : moe

    async.forEach _users, ( (s, next) => s.save next ), (error) =>
      callback error

  _initEvent : (context, callback ) ->

    uuid = context.uuid

    incorrect = new ObjectId
    correct   = new ObjectId

    context.outcome =
      incorrect : incorrect
      correct   : correct
    
    context.validOutcomes = validOutcomes = [correct, incorrect]

    _event = new Event
      name  : "#{TEST_NAME} #{uuid}"
      title : "#{TEST_NAME} #{uuid}"
      order : 0
      questionTemplate: "Question Template"
      feedTemplate: "Feed Template"
      icon: ""
      points: 1
      validOutcomes: validOutcomes
      episode: new ObjectId
      outcome: correct
      eventTemplate: new ObjectId

    _event.save (error, doc) =>
      return callback error if error
      context.event = doc
      callback undefined


  _initPredictions : (context, callback ) ->

    event = context.event

    users = context.users

    outcome = context.outcome

    context.airing = airing = new ObjectId

    _pData =
      event   : event._id
      episode : event.episode
      meta:
        airing: airing
 
    [ users.smarty.prediction, users.loosey.prediction ] = predictions = [
      new Prediction _.extend { prediction: outcome.correct,   outcome: { correct: true,  points: 1 } }
      new Prediction _.extend { prediction: outcome.incorrect, outcome: { correct: false, points: 1 } }
    ]


    context.users = users

    async.forEach predictions, ( (p, next) => p.save next ), callback

  _initScoreEventGroup : ( context, callback ) ->
    event   = context.event
    airing  = context.airing

    _sEventGroup =
      event   : event._id
      airing  : airing
      state   : 'closed'

    sEventGroup = new ScoreEventGroup _sEventGroup
    sEventGroup.save (error, doc) =>
      return callback error if error
      context.scoreEventGroup = doc
      callback undefined



module.exports = new ScoreEventGroupFixtures
