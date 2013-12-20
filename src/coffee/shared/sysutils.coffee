###
* Copyright (c) 2011 Hans Gill. All rights reserved. Copyrights licensed under the New BSD License.
* See LICENSE file included with this code project for license terms.
###
sys      = require 'sys'
conf = require "./conf"


class DateHelper

  currentYearAndWeek : () ->
    @getYearAndWeek()

helper = module.exports =
  mongoArrayToJSON: (docArray)->
    res = []
    docArray.forEach( (doc)-> res.push(doc.toJSON()))
    res
  
  randomInt: (max)->
    Math.floor(Math.random()*max)
  
  arrayContains: (array, element)->
    found = false
    array.forEach (el)->
      if(el == element)
        found = true
    found

  getHeightInches: (height)->
    heightStr = height.toString()
    #console.log "getHeightInches #{height}"
    #console.log "heightStr.slice(0,1) : #{heightStr.slice(0,1)}"
    #console.log "heightStr.slice(1) : #{heightStr.slice(1)}"
    feet = parseInt(heightStr.slice(0,1),10)
    #console.log "feet : #{feet}"
    inches = parseInt(heightStr.slice(1),10)
    #console.log "inches : #{inches}"
    newHeightInches = (feet * 12 + inches)
    return newHeightInches

  getHeightOurFormat: (inches)->
    feet = Math.floor inches / 12
    #console.log "feet : #{feet}"
    inches = inches % 12
    inches = if inches > 9 then inches.toString() else "0"+inches.toString()
    #console.log "inches : #{inches}"
    ourFormatHeight = parseInt((feet.toString())+inches)
    return ourFormatHeight


  #remember we save height as 411, 506, 601 number
  subtractHeight: (height, amount)->
    ###console.log "subtract height"
    console.log "height: #{height}"
    console.log "height inches : #{@getHeightInches(height)}"
    console.log "amount: #{amount}"
    console.log @getHeightOurFormat(@getHeightInches(height) - amount)###
    return @getHeightOurFormat(@getHeightInches(height) - amount)

  addHeight: (height, amount)->
    ###console.log "add height"
    console.log "height: #{height}"
    console.log "height inches : #{@getHeightInches(height)}"
    console.log "amount: #{amount}"
    console.log @getHeightOurFormat(@getHeightInches(height) + amount)###
    return @getHeightOurFormat(@getHeightInches(height) + amount)


    




  dates: new DateHelper
