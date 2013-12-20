should  = require 'should'
uuid    = require 'node-uuid'

ObjectId = (require 'mongoose').Types.ObjectId

require "../../../lib/shared/models/mongo"
{ Event } = require '../../../lib/shared/models/event'


describe "Event Model", (done) ->

