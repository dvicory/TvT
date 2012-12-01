EventEmitter2 = require('eventemitter2').EventEmitter2

# EventEmitter that is compatible and can be swapped in place with pulse.EventManager
#
# @note The rationale to use EventEmitter is that its backend is provided by {https://github.com/hij1nx/EventEmitter2 EventEmitter2},
#   which is fast and provides many extra features over pulse.EventManager
# @see https://github.com/onmodulus/pulse/blob/1.3-r1/lib/pulse/src/event/eventmanager.js pulse.EventManager implementation reference
# @copyright BZFX
# @author Daniel Vicory
# @author OnModulus
#
class EventEmitter extends EventEmitter2
  # @property [Object] holds currently dragged objects
  DraggedItems: {}

  # @property [Object] holds objects intended to be private
  # @private
  _private: {}

  # Constructs a new EventEmitter
  #
  # @example Construct a new EventEmitter
  #   new EventEmitter,
  #     owner: [Object]
  #     masterCallback: [Function]
  #     wildcard: false
  #     delimiter: '.'
  #     maxListeners: 10
  #
  # @param [Object] options the new EventEmitter options
  # @option options [Object] owner owner of the emitter, if any - masterCallback will be called with {owner} as a given this
  # @option options [Function] masterCallback callback that is called for any emitted event
  # @option options [Boolean] wildcard enable wildcards
  # @option options [String] delimiter delimiter for namespaced events
  # @option options [Number] maxListeners maximum number of listeners on an event before a warning is raised, helpful to find memory leaks
  constructor: (options) ->
    options = pulse.util.checkParams options,
      owner: null
      masterCallback: null
      wildcard: false
      delimiter: '.'
      maxListeners: 10

    @owner = options.owner
    @masterCallback = options.masterCallback
    @_private.touchDown = false

    super
      wildcard: options.wildcard
      delimiter: options.delimiter
      maxListeners: options.maxListeners

  # Binds a listener to an event.
  #
  # @param [String] event the event that listener will be called on
  # @param [Function] listener the listener to callback when event is emitted
  bind: (event, listener) ->
    @on(event, listener)

  # Uninds all listener from an event.
  #
  # @param [String] event the event to remove all listeners from
  unbind: (event) ->
    @removeAllListeners event

  # Uninds a specific listener from an event.
  #
  # @param [String] event the event to remove a specific listener from
  # @param [Function] listener the specific listener to remove
  unbindFunction: (event, listener) ->
    @removeListener event, listener

  # Checks to see if a certain event has any listeners attached.
  #
  # @param [String] event the event to check if there are listeners
  # @return [Boolean] true if the event has attached listeners, otherwise false
  hasEvent: (event) ->
    return true if @listeners(event).length isnt 0
    return false

  # Raises an event, passing on data to any attached listeners to that event.
  # Also raises the master callback, if one is defined.
  #
  # @param [String] event the event to emit
  # @param [Object] data the data to give to the listeners on the event
  raiseEvent: (event, data) ->
    # magic to make events for touch interfaces nicer
    if event is 'touchstart' and @_private.touchDown is false
      @_private.touchDown = true
    else if event is 'touchend' and @_private.touchDown is true
      @raiseEvent 'touchclick', data
    else if event is 'touchclick' or event is 'mouseout'
      @_private.touchDown = false

    # fire the event
    @emit event, data

    # let's see if there's a catch-all listener for all events
    if typeof @masterCallback is 'function'
      if @owner?
        @masterCallback.call @owner, event, data
      else
        @masterCallback event, data

  # Checks to see if a specific event type needs to be translated, and returns it.
  #
  # @param [String] type the event type to check
  # @return [String] the type to use, either what was originally passed in type, or a translated one
  checkType: (type) ->
    if type is 'click' and pulse.util.eventSupported('touchend')
      return 'touchclick'

    for t in pulse.eventtranslations
      return t if type is pulse.eventtranslations[t] and pulse.util.eventSupported(t)

    type

module.exports = EventEmitter
