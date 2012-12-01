class VariableDatabaseValue
  constructor: (val) ->
    # coerce into a primitive
    val = val.valueOf()

    if typeof val isnt 'number' and typeof val isnt 'string'
      throw new TypeError('variable database only supports storing variables of type number or string')

    @type = typeof val

    # backing property for default
    Object.defineProperty @, '_default',
      enumerable: false
      writable: true
      value: val

    # user-exposed default, this does type checking against type
    Object.defineProperty @, 'default',
      enumerable: true
      get: ->
        @_default
      set: (val) ->
        # coerce out
        val = val.valueOf()

        if typeof val isnt @type
          throw new TypeError("cannot store #{val} as it does not match type #{@type}")
        else
          @_default = val

    # backing property for value
    Object.defineProperty @, '_value',
      enumerable: false
      writable: true
      value: @default

    # user-exposed value, this does type checking against type
    Object.defineProperty @, 'value',
      enumerable: true
      get: ->
        @_value
      set: (val) ->
        # coerce out
        val = val.valueOf()

        if typeof val isnt @type
          throw new TypeError("cannot store #{val} as it does not match type #{@type}")
        else
          @_value = val

class VariableDatabase
  constructor: ->
    @variables = {}

  get: (name) ->
    if @variables[name]?
      return @variables[name]
    else
      throw new ReferenceError("#{name} does not exist in variable database")

  exists: (name) ->
    @variables[name]?

  set: (name, value) ->
    # does it already exist?
    if @variables[name]?
      variables[name].value = value
    else
      # else we'll just create it now, with the default set to value
      variables[name] = new VariableDatabaseValue(value)

    return variables[name]

  reset: (name) ->
    if variables[name]?
      variables[name].value = variables[name].default

module.exports = VariableDatabase
