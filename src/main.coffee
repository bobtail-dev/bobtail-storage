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
    serialize: (v) -> if v then 1 else 0
    deserialize: (v) -> not not parseInt v
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
  windowStorage[__storageTypeKey] = storageType
  defaultState = {}
  defaultState[__storageTypeKey] = storageType
  storageMap = rx.map windowStorage

  $(window).bind 'storage', ({originalEvent}) ->
    {key, newValue, oldValue, storageArea} = originalEvent
    if storageArea[__storageTypeKey] == storageType
      if not key? then storageMap.update defaultState
      else if newValue != oldValue then storageMap.put key, newValue

  rx.autoSub storageMap.onAdd, ([k, n]) ->
    if windowStorage.getItem(k) != n then windowStorage.setItem k, n
  rx.autoSub storageMap.onChange, ([k, o, n]) ->
    if windowStorage.getItem(k) != n then windowStorage.setItem k, n
  rx.autoSub storageMap.onRemove, ([k, o]) -> windowStorage.removeItem k

  # necessary because SrcMap objects do not permit deleting nonexistent keys.
  safeRemove = (k) ->
    map = rx.snap -> storageMap.all()
    if k of map then storageMap.remove k

  _removeItem = (k) ->
    if k != __storageTypeKey then prefixFuncs.forEach (func) -> safeRemove func k

  _getItem = (k) ->
    t = _.chain(types)
         .values()
         .find((v) -> storageMap.get(v.prefixFunc k))
         .value()
    t?.deserialize storageMap.get(t.prefixFunc k)

  return {
    getItem: (k) -> rx.snap -> _getItem(k)
    getItemBind: (k) -> rx.bind -> _getItem(k)
    removeItem: (k) -> rx.transaction -> _removeItem k
    setItem: (k, v) -> if k != __storageTypeKey then rx.transaction ->
      if _getItem(k) != v
        _removeItem k
        type = getType v
        storageMap.put type.prefixFunc(k), type.serialize(v)
    clear: -> storageMap.update defaultState
    onAdd: storageMap.onAdd
    onRemove: storageMap.onRemove
    onChange: storageMap.onChange
  }

window.rxStorage.local = storageMapObject "local"
window.rxStorage.session = storageMapObject "session"
