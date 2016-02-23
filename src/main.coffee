{rx, _} = window
window.rxStorage = {}

# used to allow us to identify which keys have JSON values. Don't use this as a prefix to any of your keys.
__prefix = "__4511cb3d-d420-4a8c-8743-f12ef5e45c3e__reactive__storage"

# Exported for testing purposes.
__storageTypeKey = window.rxStorage.__storageTypeKey = "#{__prefix}__type"

__jsonPrefix = "#{__prefix}__json__"
__boolPrefix = "#{__prefix}__bool__"
__numberPrefix = "#{__prefix}__number__"
__nullPrefix = "#{__prefix}__null__"

jsonPrefix = window.rxStorage.__jsonPrefix = (k) -> "#{__jsonPrefix}#{k}"
boolPrefix = window.rxStorage.__boolPrefix = (k) -> "#{__boolPrefix}#{k}"
numberPrefix = window.rxStorage.__numberPrefix = (k) -> "#{__numberPrefix}#{k}"
nullPrefix = window.rxStorage.__nullPrefix = (k) -> "#{__nullPrefix}#{k}"

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
  null: {prefixFunc: nullPrefix, serialize: _.identity, name: 'null', deserialize: -> null}
}

prefixFuncs = _.chain(types).values().pluck('prefixFunc').uniq().value()

getType = (v) ->
  if v is null then types.null
  else types[typeof v]

storageMapObject = (storageType) ->
  windowStorage = window["#{storageType}Storage"]
  windowStorage[__storageTypeKey] ?= storageType
  defaultState = ->
    r = {}
    r[__storageTypeKey] = storageType
    r
  storageMap = rx.map _.clone windowStorage

  writeGuard = false # used to prevent multi-tab update loops.

  window.addEventListener 'storage', ({key, newValue, oldValue, storageArea}) ->
    if not key?
      storageMap.update defaultState()
    else if storageArea[__storageTypeKey] == storageType and newValue != oldValue
      writeGuard = true
      storageMap.put key, newValue
      writeGuard = false

  rx.autoSub storageMap.onAdd, (dict) ->
    if not writeGuard then _.pairs(dict).forEach ([k, n]) -> windowStorage.setItem k, n
  rx.autoSub storageMap.onChange, (dict) ->
    if not writeGuard then _.pairs(dict).forEach ([k, [o, n]]) -> windowStorage.setItem k, n
  rx.autoSub storageMap.onRemove, (dict) ->
    _.keys(dict).forEach (k) -> windowStorage.removeItem k

  # necessary because SrcMap objects do not permit deleting nonexistent keys.
  _safeRemove = (k) ->
    map = rx.snap -> storageMap.all()
    if k of map then storageMap.remove k

  _removeItem = (k) ->
    if k != __storageTypeKey then rx.transaction ->
      prefixFuncs.forEach (func) -> _safeRemove func k

  _getItem = (k) ->
    t = _.chain(types)
         .values()
         .find((v) -> storageMap.get(v.prefixFunc k))
         .value()
    t?.deserialize storageMap.get(t.prefixFunc k)


  _setItem = (k, v) ->
    if k != __storageTypeKey then rx.transaction ->
      o = _getItem(k)
      if o != v
        if typeof(o) != typeof(v) then _removeItem k
        type = getType v
        storageMap.put type.prefixFunc(k), type.serialize(v)

  return {
    getItem: (k) -> rx.snap -> _getItem(k)
    getItemBind: (k) -> rx.bind -> _getItem(k)
    removeItem: (k) -> rx.transaction -> _removeItem k
    setItem: (k, v) -> _setItem(k, v)
    clear: -> storageMap.update defaultState()
    onAdd: storageMap.onAdd
    onRemove: storageMap.onRemove
    onChange: storageMap.onChange
  }

window.rxStorage.local = storageMapObject "local"
window.rxStorage.session = storageMapObject "session"

window.localStorage.clear = -> console.error "Manually clearing localStorage will cause the local storage map object to break. Use rxStorage.local.clear() instead."
window.sessionStorage.clear = -> console.error "Manually clearing localStorage will cause the local storage map object to break. Use rxStorage.local.clear() instead."
