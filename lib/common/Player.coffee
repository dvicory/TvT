DynamicWorldObject = require('./DynamicWorldObject')
Shot = require('./Shot')

class Player extends DynamicWorldObject
  constructor: (@slot, @team, @callsign, @tag, @wins, @losses) ->
    super 'Player'

    @wins   ?= 0
    @losses ?= 0
    @shots   = []

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

  die: (killer, shot) ->
    return false unless @_state is 'alive'

    @_state = 'dead'

    @emit 'died', @, killer, shot

    # update losses
    @losses++
    @emit 'updated.score', @

  kill: (killee, shot) ->
    return false unless @_state is 'alive'

    @emit 'killed', @, killee, shot

    # update wins
    @wins++
    @emit 'updated.score', @

  shoot: (slot, initialPosition, rotation) ->
    slot ?= @shots.length

    shot = new Shot(slot, @, initialPosition, rotation)

    @shots.push(shot)

    return shot

  endShot: (endedShot) ->
    i = 0

    for shot in @shots
      if shot is endedShot
        @shots[i] = null
        @shots.splice(i, 1)

        break

      i++

module.exports = Player
