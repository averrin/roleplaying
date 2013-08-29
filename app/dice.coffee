#exports.Dice = ->

roll = (nDice, faces, operation, addTotal) ->
    tempResult = 0
    i = 0

    while i < nDice
      tmpNum = parseInt(new Number(Math.random() * faces))
      tmpNum = 1  if tmpNum is 0
      tempResult += parseInt(tmpNum)
      i++
    if operation is "+"
      tempResult += parseInt(addTotal)
    else
      tempResult -= parseInt(addTotal)
    (if (tempResult < 0) then 0 else tempResult)

exports.rollDie = (diceString) ->
    regExpDice = "([0-9]{1,100})d([0-9]{1,100})(\\+|\\-){0,1}(([0-9]{1,100})){0,1}"
    RegExpObject = new RegExp(regExpDice)
    matches = RegExpObject.exec(diceString)
    #console.log matches
    if matches.length is 6
      if matches[3] is undefined
        roll matches[1], matches[2], 0, 0
      else
        roll matches[1], matches[2], matches[3], matches[4]
    #else
      #console.log matches.length
