{rx, rxStorage} = window
{bind} = rx
{local, session} = rxStorage
R = rx.rxt.tags

init = ->
  localCheckKeys = [0..3].map (i) -> "localCheck#{i}"
  sessionCheckKeys = [0..3].map (i) -> "sessionCheck#{i}"

  $('body').append R.div [
    R.h1 "Local Checks"
    R.div localCheckKeys.map (key) ->
      R.div [
        R.label [
          key
          " "
          R.input {
            type: 'checkbox'
            change: -> local.setItem(key, not local.getItem(key))
            checked: bind -> !!local.getItemBind(key).get()
          }
        ]
      ]
    R.button {type: 'button', click: -> local.clear()}, "Clear"

    R.h1 "Session Checks"
    R.div sessionCheckKeys.map (key) ->
      R.div [
        R.label rx.flatten [
          key
          " "
          R.input {
            type: 'checkbox'
            click: -> session.setItem(key, not session.getItem(key))
            checked: bind -> !!session.getItemBind(key).get()
          }
          " "
          R.span bind -> "#{session.getItemBind(key).get()}"
        ]
      ]
    R.button {type: 'button', click: -> session.clear()}, "Clear"
  ]

init()
