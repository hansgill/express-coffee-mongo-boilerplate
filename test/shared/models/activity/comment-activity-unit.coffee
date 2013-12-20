_       = require 'underscore'

should  = require 'should'
sinon   = require 'sinon'
uuid    = require 'node-uuid'

async   = require 'async'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../../lib/shared/models/mongo"

{ ActivityFactory } = require '../../../../lib/shared/models/activity'

platform      = require 'hashgo-platform'


describe "Creation of an Activity from a Comment", () ->

    ### User returned by the platform. ###
    mockUser =
      prn   : "curly-#{uuid.v1()}@activity-unit-test"
      alias : "Curly"
      user_img_http   : "http://upload.wikimedia.org/wikipedia/en/thumb/4/4e/Curlyhoward.jpg/200px-Curlyhoward.jpg"
      user_img_https  : "http://upload.wikimedia.org/wikipedia/en/thumb/4/4e/Curlyhoward.jpg/200px-Curlyhoward.jpg"
    ### Comment data ###
    comment =
      _id : new ObjectId
      hgId: mockUser.prn
      episodeKey:
        episode : new ObjectId
        airing  : new ObjectId
      message: "Important comment message."

    before (done) ->
      ### Register the Stub to avoid calling the platform endpoints and return the mock User Data..###
      sinon.stub platform.users.q, "principals", ( ids, callback ) ->
        result =
          data : [
            [ mockUser.hgId, mockUser ]
          ]
        callback undefined, result

      done()
          
    after (done) ->
      ### When done ensure that we return the hashgo platform api to its good known state.###
      platform.users.q.principals.restore()
      done()

    activityInstance = undefined

    it "should be able to build an _Activity_ for a _Comment_ ", (done) ->
      ActivityFactory.process "comment:created", comment, ( error, instance ) ->
        should.not.exist error
        should.exist instance
        activityInstance = instance
        done()

    it "should have a source", ->
      activityInstance.source.should.eql comment._id
 
    it "should have a type", ->
      activityInstance.type.should.eql "comment:created"
      
    it "should have a body", ->
      activityInstance.body.text.should.eql comment.message

    it "should have a timestamp", ->
      should.exist activityInstance.timestamp

    it "should have a episodeKey", ->
      should.exist activityInstance.episodeKey
      episodeKey = activityInstance.episodeKey
      episodeKey.episode.should.eql comment.episodeKey.episode
      episodeKey.airing.should.eql comment.episodeKey.airing

    it "should have a user", ->
      should.exist activityInstance.user
      _user = activityInstance.user
      _user.hgId.should.eql mockUser.prn
      _user.alias.should.eql mockUser.alias
      _user.userImgHttp.should.eql mockUser.user_img_http
      _user.userImgHttps.should.eql mockUser.user_img_https
