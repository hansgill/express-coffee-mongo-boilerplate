_       = require 'underscore'
async   = require 'async'
should  = require 'should'
uuid    = require 'node-uuid'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../lib/shared/models/mongo"

{Event} = require '../../../lib/shared/models/event'
{Prediction} = require '../../../lib/shared/models/prediction'

#scoreWorkers = require "../../../lib/shared/workers/score"
#scoreWorkers.predictionOutcomeWorker.initWorkers()
#scoreWorkers.predictionMadeWorker.initWorkers()


describe "Prediction Model", (done) ->

  incorrectOutcomes = [1..3].map (e) =>  new ObjectId

  correctOutcome = new ObjectId

  validOutcomes = _.union [correctOutcome], incorrectOutcomes

  # published Event
  _result = {}
  # Capture the start time in millis
  startTime = ( new Date ).getTime()
  # event pointer
  event = undefined
  # prediction pointer
  prediction = undefined

  inputData =
    airing  : new ObjectId
    user:
      session: uuid.v1()
      hgId: uuid.v1()
    prediction : incorrectOutcomes


  before (done) ->
    eventUuid = uuid.v1()

    _event = Event
      episode: new ObjectId
      name  : "event-#{eventUuid}"
      title : "event #{eventUuid}"
      order : 1
      questionTemplate: "Question Template for #{eventUuid}"
      feedTemplate: "Feed Template for #{eventUuid}"
      icon: ""
      points: 1
      validOutcomes: validOutcomes
      outcome: correctOutcome
      eventTemplate: new ObjectId

    inputData.event       = _event._id
    inputData.episode     = _event.episode

    _event.save (error, doc) =>
      should.not.exist error
      should.exist doc
      event = doc
      done()
    

  describe "submitting a prediciotn", (done)->

    it "should call the action", (done)->

      Prediction.submit inputData, (error, doc) =>
        should.not.exist error
        should.exist doc
        prediction = doc
        done()

    describe "asserting the returned reference", ->

      json = undefined

      it "can transform to JSON" , ->
        json = prediction.toJSON()

      it "has an _id ", ->
        should.exist json._id

      it "has an episode", ->
        json.episode.should.eql inputData.episode

      it "has an event", ->
        json.event.should.eql inputData.event

      it "has the prediction ", ->
        json.prediction.should.eql inputData.prediction

      it "has the user", ->
        json.user.should.eql inputData.user

      it "has the meta with an airing", ->
        json.meta.airing.should.eql inputData.airing

      it "has the correct state", ->
        json.state.should.eql 'pending'

      it "has the correct edits", ->
        json.edits.should.eql 0

  describe "updating the prediction", (done)->

    it "should be able to update the prediction", (done) ->

      prediction.updatePrediction correctOutcome, (error, doc) ->
        should.not.exist error
        should.exist doc
        prediction = doc
        done()

    describe "structure after updating the prediction", ->

      json = undefined

      it "can transform to JSON", ->
        json = prediction.toJSON()

      it "has the expected prediction", ->
        json.prediction.should.eql [correctOutcome]

      it "has an incremented number of edits", ->
        json.edits.should.eql 1

  describe "closing predictions", ->

    incorrectPredictions = undefined

    # TODO add prediction with a different airing.
    before (done)->
      predictions = [ ]
      async.map [1..3], ( (i, next) =>
        _input =
          prediction: [ new ObjectId ]
          user:
            session: uuid.v1()
            hgId: uuid.v1()

        _data = _.extend _input, inputData

        Prediction.submit _data, next

      ), (error, results) =>
        should.not.exist error
        incorrectPredictions = results
        done()
      
    it "should be able to close all predictions associated with an event and airing", (done) ->

      Prediction.close event, inputData.airing, (error, closedPredictions) ->
        should.not.exist error
        closedPredictions.should.have.lengthOf( incorrectPredictions.length + 1)
        done()

    describe "asserting the state of the closed predictions", (done)->
      
      it "must set the outcome.correct to false for those predictions that did not match.", (done)->
        ids = incorrectPredictions.map (e) => e._id

        Prediction.find { _id : { $in : ids }, "outcome.correct" : false }, (error, docs) =>
          should.not.exist error
          should.exist docs
          docs.should.have.lengthOf ids.length
          done()

      it "must set the outcome.correct to true for those predictions that did match.", (done)->
        ids = [ prediction._id ]

        Prediction.find { _id : { $in : ids }, "outcome.correct" : true }, (error, docs) =>
          should.not.exist error
          should.exist docs
          docs.should.have.lengthOf ids.length
          done()

