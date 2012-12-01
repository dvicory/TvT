DynamicWorldObject = require('./DynamicWorldObject')

class Player extends DynamicWorldObject
  constructor: (@slot, @team, @callsign, @tag, @wins, @losses) ->
    super 'Player'

    @wins   ?= 0
    @losses ?= 0

    Object.defineProperty @, 'score',
      enumerable: false
      value: @wins - @losses

    Object.defineProperty @, '_state',
      enumerable: false
      value: 'idle'

  update: (elapsedMS) ->
    super elapsedMS

  spawn: (position, rotation) ->
    @position = position
    @rotation = rotation

    @_state = 'alive'

    @emit 'spawned', @

  die: (killer) ->
    return false unless @_state is 'alive'
    @_state = 'dead'

    @emit 'died', @, killer

    # update losses
    @losses++
    @emit 'updated.score', @

  kill: (killee) ->
    return false unless @_state is 'alive'

    @emit 'killed', @, killee

    # update wins
    @wins++
    @emit 'updated.score', @

module.exports = Player
