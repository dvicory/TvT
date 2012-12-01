EventEmitter2 = require('eventemitter2').EventEmitter2

class WorldObject extends EventEmitter2
  constructor: (_type) ->
    # setup EventEmitter2
    super wildcard: true, newListener: true, maxListeners: 10

    _type ?= 'WorldObject'

    Object.defineProperty @, 'type',
      enumerable: true
      value: _type

    # we don't want the events stuff to be enumerable
    # that way we can easily JSON.stringfy the world objects and send them over the network
    props = ['_events', 'wildcard', 'listenerTree']
    for prop in props
      pd = Object.getOwnPropertyDescriptor(@, prop)
      pd.enumerable = false
      Object.defineProperty @, prop, pd

module.exports = WorldObject
