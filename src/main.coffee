_ = window._
window.rxStorage = {}

# used to allow us to identify which keys have JSON values. Don't use this as a prefix to any of your keys.
window.rxStorage.__jsonPrefix = "__4511cb3d-d420-4a8c-8743-f12ef5e45c3e__reactive__storage__json__"
jsonPrefix = (k) -> "#{window.rxStorage.__jsonPrefix}#{k}"

storageMapObject = (windowStorage={}) ->
  storageMap = rx.map windowStorage

  $(window).bind 'storage', (event) ->
    if event.storageAreaArg == windowStorage
      if event.key is null then windowStorage.update {}
      else windowStorage.put event.key, event.newValueArg

  rx.autoSub storageMap.onAdd, ([k, n]) -> window.localStorage.setItem k, n
  rx.autoSub storageMap.onChange, ([k, o, n]) -> window.localStorage.setItem k, n
  rx.autoSub storageMap.onRemove, ([k, o]) -> window.localStorage.removeItem k

  # necessary because SrcMap objects do not permit deleting nonexistent keys.
  safeRemove = (k) ->
    map = rx.snap -> _.keys storageMap.all()
    if k of map then storageMap.remove k

  return {
    getItem: (k) ->
      jsonV = storageMap.get(jsonPrefix k)
      if jsonV? then JSON.parse jsonV
      else return storageMap.get k
    removeItem: (k) ->
      safeRemove k
      safeRemove jsonPrefix k
    setItem: (k, v) ->
      toStore = {k, v}
      if typeof v in ['array', 'object']
        # If we stored a string in k, and then a JSON object in k, the JSON object should replace the string
        safeRemove k
        toStore.k = jsonPrefix k
        toStore.v = JSON.stringify v
      else
        # and vice versa
        safeRemove jsonPrefix k
      storageMap.put toStore.k, toStore.v
    clear: -> storageMap.update {}
    update: (contents) -> storageMap.update contents
    onAdd: storageMap.onAdd
    onRemove: storageMap.onRemove
    onChange: storageMap.onChange
  }

window.rxStorage.localStorage = storageMapObject window.localStorage
window.rxStorage.sessionStorage = storageMapObject window.sessionStorage
