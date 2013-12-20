_       = require 'underscore'
async   = require 'async'
should  = require 'should'
uuid    = require 'node-uuid'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../lib/shared/models/mongo"

{Event, EventAiringState} = require '../../../lib/shared/models/event'

#scoreWorkers = require "../../../lib/shared/workers/score"
#scoreWorkers.predictionOutcomeWorker.initWorkers()
#scoreWorkers.predictionMadeWorker.initWorkers()

describe "Event Airing State", (done) ->

  initData =
    event   : new ObjectId
    airing  : new ObjectId

  # published Airing State
  airingState = undefined
  # Capture the start time in millis
  startTime = ( new Date ).getTime()

  it "should publish an airing", (done)->
    EventAiringState.publish initData, (error, doc) =>
      should.not.exist error
      should.exist doc
      airingState = doc
      done()

  describe "returned structure", ->
    it "has an _id ", ->
      should.exist airingState._id

    it "has an episode", ->
      airingState.event.should.eql initData.event

    it "has an airing", ->
      airingState.airing.should.eql initData.airing

    it "has the correct status", ->
      airingState.status.should.eql 'published'

    it "has a dateCreated", ->
      airingState.dateCreated.should.be.ok


  it "should be able to lock a published event", (done) ->
    EventAiringState.lock airingState, (error, _airingState) =>
      should.not.exist error
      should.exist _airingState

      _airingState._id.should.eql airingState._id
      _airingState.status.should.eql 'locked'
      airingState = airingState
      done()


  it "should not be able to lock an event that is already locked.", (done) ->
    EventAiringState.lock airingState, (error, _airingState) =>
      should.not.exist error
      should.not.exist _airingState
      done()

  it "should be able to unlock an event that is locked.", (done) ->
    EventAiringState.unlock airingState, (error, _airingState) =>
      should.not.exist error
      should.exist _airingState

      _airingState._id.should.eql airingState._id
      _airingState.status.should.eql 'published'
      airingState = airingState
      done()

  it "should be able to close an event that is locked.", (done) ->
    EventAiringState.lock airingState, (error, _airingState) =>
      should.not.exist error
      should.exist _airingState
      _airingState.status.should.eql 'locked'

      EventAiringState.close _airingState, (error, _closedAiringState ) =>
        _closedAiringState.status.should.eql 'closed'
        _closedAiringState._id.should.eql airingState._id
        done()

