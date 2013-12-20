require 'colors'
_       = require 'underscore'
async   = require 'async'
moment  = require 'moment'
should  = require 'should'
uuid    = require 'node-uuid'
moment  = require 'moment'

# Mongoose Types
ObjectId = (require 'mongoose').Types.ObjectId

# application system utilities
sysutils = require '../../../lib/shared/sysutils'

# initialize mongoose connections
require "../../../lib/shared/models/mongo"

# import the Score Models
{ScoreEvent, WeeklyScore, AllTimeScore } = require '../../../lib/shared/models/score/score'

###
# Helper Functions
###
genHgId = () ->
  "#{uuid.v1()}@weekly-user-score-test"


createScoreEvent = ( args = {} ) ->
  
  hgId      = args.hgId   ?   genHgId()
  clubId    = args.clubId ? new ObjectId
  meta      = args.meta
  show      = args.show  ? new ObjectId
  type      = args.type      ? "a_type"
  score     = args.score     ? 1
  timestamp = args.timestamp ? Date.now()

  data =
    hgId        : hgId
    clubId      : clubId
    meta        : meta
    show        : show
    scoreType   : type
    score       : score
    timestamp   : timestamp

  scoreEvent = new ScoreEvent data
 
###
# Specification
###
describe "Score Components", (done) ->
