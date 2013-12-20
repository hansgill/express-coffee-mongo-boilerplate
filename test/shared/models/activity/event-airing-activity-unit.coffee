_       = require 'underscore'

should  = require 'should'
sinon   = require 'sinon'
uuid    = require 'node-uuid'

async   = require 'async'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../../lib/shared/models/mongo"

{ ActivityFactory } = require '../../../../lib/shared/models/activity'

{ Event, EventAiringState } = require '../../../../lib/shared/models/event'

describe "Handling Activities for an Event Airing", (done) ->

  event = new Event
    name: "Event To Activity Test"
    title: "Event To Activity Test"
    order : 1
    feedTemplate: "Feed Template"
    icon: "/an/icon/url.png"
    points: 10
    validOutcomes: [ ]
    type: [ "contestants" ]
    episode: new ObjectId
    eventTemplate: new ObjectId


  before (done) ->
    event.save (error, record) ->
      should.not.exist error
      should.exist record
      event = record
      done()
    

  describe "when the airing is marked as published", (done) ->

    type = "event_airing:published"

    airingState =
      _id    : new ObjectId
      event  : event._id
      episode: event.episode
      airing :  new ObjectId
      status : "published"

    activityInstance = undefined

    it "should be able to build an _Activity_ ", (done) ->
      ActivityFactory.process type, airingState, ( error, instance ) ->
        should.not.exist error
        should.exist instance
        activityInstance = instance
        done()

    it "should have a source", ->
      activityInstance.source.should.eql airingState._id
 
    it "should have a type", ->
      activityInstance.type.should.eql type
      
    it "should have a body", ->
      activityInstance.body.text.should.eql event.feedTemplate

    it "should have a episodeKey", ->
      should.exist activityInstance.episodeKey

    it "should have a episodeKey.event", ->
      episodeKey = activityInstance.episodeKey
      episodeKey.episode.should.eql airingState.episode

    it "should have a episodeKey.airing", ->
      episodeKey = activityInstance.episodeKey
      episodeKey.airing.should.eql airingState.airing
