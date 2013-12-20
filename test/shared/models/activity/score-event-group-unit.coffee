_       = require 'underscore'

should  = require 'should'
sinon   = require 'sinon'
uuid    = require 'node-uuid'

async   = require 'async'

ObjectId = (require 'mongoose').Types.ObjectId

activityTypeFactory = require '../../../../lib/shared/models/activity/types/score-event-group'

scoreEventGroupFixtures = require './score-event-group-fixtures'


describe "Creating Activities from a 'Score Event Group'", (done) ->

  fixtures = undefined

  before (done) ->
    scoreEventGroupFixtures.init (error, _fixtures) =>
      should.not.exist error
      should.exist _fixtures
      fixtures = _fixtures
      done()
 

  describe "triggering Activities from a Score Event Group", (done) ->
    
    it "should process the input", (done) ->
      activityTypeFactory.process "score-event-group:closed", fixtures.scoreEventGroup, (error) =>
        should.not.exist error
        done()

 


  describe "internal methods", (done) ->

    _uuid = uuid.v1()

    hgId = "user-#{_uuid}@test"

    usersWithScores = [1..5].map (i) => "#{i}-#{_uuid}-score@test"

    friends = usersWithScores.concat [1..5].map (i) => "#{i}-#{_uuid}-no@test"

    event =
      _id : new ObjectId
      episode : new ObjectId

    airing = new ObjectId

    prediction =
      _id : new ObjectId
      user:
        hgId : hgId
      episode : event.episode
      meta:
        airing: airing
      outcome :
        points: 10

    before (done) ->
      sinon.stub activityTypeFactory, "getInGameUserFriends", ( hgId, callback ) ->
        callback undefined, friends
      done()
          
    after (done) ->
      activityTypeFactory.getInGameUserFriends.restore()
      done()

    describe "should be able to generate activities for users with correct outcomes", (done) ->

      activity = undefined

      it "should process correct outcomes", (done) ->
        activityTypeFactory._processCorrectOutcome event, "type", usersWithScores, prediction, (error, _activity, _friends) =>
          should.not.exist error
          should.exist _activity
          _friends.should.eql friends
          activity = _activity
          done()

      describe "activity structure", (done) ->

        it "should have the correct user", ->
          activity.user.hgId.should.eql hgId

        it "should have a correct userAudience", ->
          activity.userAudience.should.have.lengthOf 1
          activity.userAudience[0].should.eql hgId

        it "should have a correct body args", ->
          activity.body.args.event.should.eql event
          activity.body.args.points.should.eql prediction.outcome.points
          activity.body.args.friendsWithScores.should.eql usersWithScores

    describe "should be able to generate activities for users with incorrect outcomes", (done) ->

      activity = undefined

      it "should process incorrect outcomes", (done) ->
        activityTypeFactory._processIncorrectOutcome event, "type", usersWithScores, prediction, (error, _activity, _friends) =>
          should.not.exist error
          should.exist _activity
          _friends.should.eql friends
          activity = _activity
          done()

      describe "activity structure", (done) ->

        it "should have the correct user", ->
          activity.user.hgId.should.eql hgId

        it "should have a correct userAudience", ->
          activity.userAudience.should.have.lengthOf 1
          activity.userAudience[0].should.eql hgId

        it "should have a correct body args", ->
          activity.body.args.points.should.eql prediction.outcome.points
          activity.body.args.friendsWithScores.should.eql usersWithScores
          activity.body.args.event.should.eql event

    describe "should be able to generate activities for users that didn't participated", (done) ->

      activity = undefined

      it "should process non-participants", (done) ->
        activityTypeFactory._processNonParticipant event, airing, "type", usersWithScores, hgId, (error, _activity) =>
          should.not.exist error
          should.exist _activity
          activity = _activity
          done()

      describe "activity structure", (done) ->

        it "should have the correct user", ->
          activity.user.hgId.should.eql hgId

        it "should have a correct userAudience", ->
          activity.userAudience.should.have.lengthOf 1
          activity.userAudience[0].should.eql hgId

        it "should have a correct body args", ->
          activity.body.args.friendsWithScores.should.eql usersWithScores
          activity.body.args.event.should.eql event



    


