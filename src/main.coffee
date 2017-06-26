# used to allow us to identify which keys have JSON values. Don't use this as a prefix to any of your keys.
__prefix = "__4511cb3d-d420-4a8c-8743-f12ef5e45c3e__reactive__storage"

# Exported for testing purposes.
__storageTypeKey = "#{__prefix}__type"

__jsonPrefix = "#{__prefix}__json__"
__boolPrefix = "#{__prefix}__bool__"
__numberPrefix = "#{__prefix}__number__"
__nullPrefix = "#{__prefix}__null__"

jsonPrefix = (k) -> "#{__jsonPrefix}#{k}"
boolPrefix = (k) -> "#{__boolPrefix}#{k}"
numberPrefix = (k) -> "#{__numberPrefix}#{k}"
nullPrefix = (k) -> "#{__nullPrefix}#{k}"

types = {
  string: {prefixFunc: _.identity, serialize: _.identity, deserialize: _.identity, name: 'string'}
  number: {prefixFunc: numberPrefix, serialize: _.identity, deserialize: parseFloat, name: 'number'}
  array: {prefixFunc: jsonPrefix, serialize: JSON.stringify, deserialize: JSON.parse, name: 'array'}
  object: {prefixFunc: jsonPrefix, serialize: JSON.stringify, deserialize: JSON.parse, name: 'object'}
  boolean: {
    prefixFunc: boolPrefix
    serialize: (v) -> if v then "true" else "false"
    deserialize: (v) ->
      if v == 'true' then true
      else if v == 'false' then false
      else undefined
    name: 'boolean'
  }
  null: {prefixFunc: nullPrefix, serialize: (-> 'null'), name: 'null', deserialize: ->
    console.log 'null!'
    null
  }
}

prefixFuncs = _.chain(types).values().pluck('prefixFunc').uniq().value()

getType = (v) ->
  if v is null then types.null
  else types[typeof v]

storageMapObject = (storageType, _, rx) ->
  windowStorage = window["#{storageType}Storage"]
  windowStorage[__storageTypeKey] ?= storageType
  defaultState = -> new Map [[__storageTypeKey, storageType]]
  storageMap = rx.map _.pairs windowStorage

  writeGuard = false # used to prevent multi-tab update loops.

  window.addEventListener 'storage', ({key, newValue, oldValue, storageArea}) ->
    if not key?
      storageMap.update defaultState()
    else if storageArea[__storageTypeKey] == storageType and newValue != oldValue
      writeGuard = true
      storageMap.put key, newValue
      writeGuard = false

  rx.autoSub storageMap.onAdd, (dict) ->
    if not writeGuard then dict.forEach (n, k) -> windowStorage.setItem k, n
  rx.autoSub storageMap.onChange, (dict) ->
    if not writeGuard then dict.forEach ([o, n], k) -> windowStorage.setItem k, n
  rx.autoSub storageMap.onRemove, (dict) ->
    dict.forEach (v, k) -> windowStorage.removeItem k

  # necessary because SrcMap objects do not permit deleting nonexistent keys.
  _safeRemove = (k) ->
    if (rx.snap -> storageMap.has k) then storageMap.remove k

  _removeItem = (k) ->
    if k != __storageTypeKey then rx.transaction ->
      prefixFuncs.forEach (func) -> _safeRemove func k

  _getItem = (k) ->
    t = _.chain(types)
         .values()
         .find (v) -> storageMap.get(v.prefixFunc k)
         .value()
    t?.deserialize storageMap.get(t.prefixFunc k)


  _setItem = (k, v) ->
    if k != __storageTypeKey then rx.transaction ->
      o = _getItem(k)
      if o != v
        if o is undefined or getType(o).name != getType(v)?.name then _removeItem k
        type = getType v
        storageMap.put type.prefixFunc(k), type.serialize(v)

  return {
    getItem: (k) -> rx.snap -> _getItem(k)
    getItemBind: (k) -> rx.bind -> _getItem(k)
    removeItem: (k) -> rx.transaction -> _removeItem k
    setItem: (k, v) -> _setItem(k, v)
    clear: ->
      storageMap.update defaultState()
    all: -> storageMap.all()
    onAdd: storageMap.onAdd
    onRemove: storageMap.onRemove
    onChange: storageMap.onChange
  }

factory = (_, rx) -> {
  __storageTypeKey
  __jsonPrefix: jsonPrefix
  __boolPrefix: boolPrefix
  __numberPrefix: numberPrefix
  __nullPrefix: nullPrefix
  local: storageMapObject "local", _, rx
  session: storageMapObject "session", _, rx
}


do(root = this) ->
  deps = ['underscore', 'bobtail']

  if define?.amd?
    define deps, factory
  else if module?.exports?
    _ = require 'underscore'
    rx = require 'bobtail'
    module.exports = factory _, rx
  else if root._? and root.rx?
    {_, rx} = root
    root.rxStorage = factory _, rx
  else
    throw "Dependencies are not met for reactive: _ and $ not found"
