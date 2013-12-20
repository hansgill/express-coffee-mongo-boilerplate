_       = require 'underscore'

should  = require 'should'
sinon   = require 'sinon'
uuid    = require 'node-uuid'

async   = require 'async'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../../lib/shared/models/mongo"

{ ActivityFactory } = require '../../../../lib/shared/models/activity'

{ Event, EventAiringState } = require '../../../../lib/shared/models/event'

describe "Handling Episode Airing Announcements", (done) -> 
  type = "episode_airing:announce"

  data =
    episodeKey:
      episode: new ObjectId
      airing:  new ObjectId
    announcement : "My fellow Americans, today is our Independence day!"

  activityInstance = undefined

  it "should be able to build an _Activity_ ", (done) ->
    ActivityFactory.process type, data, ( error, instance ) ->
      should.not.exist error
      should.exist instance
      activityInstance = instance
      done()

  it "should be missing a source", ->
    should.not.exist activityInstance.source

  it "should have a type", ->
    activityInstance.type.should.eql type
    
  it "should have a body", ->
    activityInstance.body.text.should.eql data.announcement

  it "should have a episodeKey", ->
    should.exist activityInstance.episodeKey
    episodeKey = activityInstance.episodeKey
    episodeKey.episode.should.eql data.episodeKey.episode
    episodeKey.airing.should.eql data.episodeKey.airing
