_       = require 'underscore'

should  = require 'should'

{ ActivityFactory } = require '../../../../lib/shared/models/activity'

describe "Activity Factory", () ->
      
    it "should send an error if the type is not recognized.", (done) ->
      ActivityFactory.process "bubbles:show", {}, ( error, activity ) =>
        should.exist error
        done()

