_       = require 'underscore'
async   = require 'async'
should  = require 'should'
uuid    = require 'node-uuid'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../lib/shared/models/mongo"

{EventAiringWorker} = require '../../../lib/shared/workers/event'
{Event, EventAiringState} = require '../../../lib/shared/models/event'
{Prediction} = require '../../../lib/shared/models/prediction'

describe "Event Workers", (done) ->

  uuid = uuid.v1()

  validOutcomes = [0..3].map (e) =>  new ObjectId

  outcome = validOutcomes[0]

  event = undefined

  before (done)->
    _event = new Event
      name  : "Test Event #{uuid}"
      title : "Test Event Title #{uuid}"
      order : 0
      questionTemplate: "Question Template"
      feedTemplate: "Feed Template"
      icon: ""
      points: 1
      validOutcomes: validOutcomes
      episode: new ObjectId
      outcome: outcome
      eventTemplate: new ObjectId

    _event.save (error, doc) =>
      should.not.exist error
      should.exist doc
      event = doc
      done()

  describe "closing an event associated with Predictions", (done) ->

    worker = new EventAiringWorker

    predictions = undefined

    eventAiring = undefined

    before (done)->

      data =
        event: event._id
        airing: new ObjectId

      EventAiringState.publish data, (error, doc) =>
        should.not.exist error
        should.exist doc
        eventAiring = doc
        
        predictionTemplate =
          event   : event._id
          episode : event.episode
          meta:
            airing : eventAiring.airing

        _funcs = [0..3].map (e) => (next) ->
          _data =
            user:
              session : "#{uuid}-#{e}@unit-test"
              hgId    : "#{uuid}-#{e}@unit-test"
            prediction: validOutcomes[e]

          prediction = new Prediction _.extend _data, predictionTemplate
          prediction.save (error, prediction) =>
            next error, prediction

        
        async.series _funcs, (error, results) =>
          should.not.exists error
          should.exist results
          predictions = results
          done()

    it "should be able to process a closed Event Airing State", (done) ->
      EventAiringState.close eventAiring, (error, airing ) =>
        should.not.exist error
        should.exist airing

        worker.process airing, (error) =>
          should.not.exist error
          done()

    describe "prediction state changes", (done) ->

      _incorrect  = undefined
      _correct    = undefined

      before (done) ->
        _incorrect = _.union [], predictions
        _correct   = _incorrect.shift()
        done()

      it "should close the correct prediction", (done)->
        Prediction.findById _correct._id, (error, prediction) =>
          should.not.exist error
          prediction.outcome.correct.should.be.ok
          prediction.state.should.eql 'closed'
          done()

      it "should close the incorrect predictions", (done) ->
        Prediction.find { _id : {$in: (_incorrect.map (e) -> e._id) }}, (error, docs) =>
          should.not.exist error
          should.exist docs
          docs.should.have.lengthOf validOutcomes.length - 1
          for doc in docs
            doc.outcome.correct.should.eql false
            doc.state.should.eql 'closed'
          done()

