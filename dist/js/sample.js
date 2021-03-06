// Generated by CoffeeScript 1.10.0
(function() {
  var R, bind, init, local, rx, rxStorage, session;

  rx = window.rx, rxStorage = window.rxStorage;

  bind = rx.bind;

  local = rxStorage.local, session = rxStorage.session;

  R = rx.rxt.tags;

  init = function() {
    var localCheckKeys, sessionCheckKeys;
    localCheckKeys = [0, 1, 2, 3].map(function(i) {
      return "localCheck" + i;
    });
    sessionCheckKeys = [0, 1, 2, 3].map(function(i) {
      return "sessionCheck" + i;
    });
    return $('body').append(R.div([
      R.h1("Local Checks"), R.div(localCheckKeys.map(function(key) {
        return R.div([
          R.label([
            key, " ", R.input({
              type: 'checkbox',
              change: function() {
                return local.setItem(key, !local.getItem(key));
              },
              checked: bind(function() {
                return !!local.getItemBind(key).get();
              })
            })
          ])
        ]);
      })), R.button({
        type: 'button',
        click: function() {
          return local.clear();
        }
      }, "Clear"), R.h1("Session Checks"), R.div(sessionCheckKeys.map(function(key) {
        return R.div([
          R.label(rx.flatten([
            key, " ", R.input({
              type: 'checkbox',
              click: function() {
                return session.setItem(key, !session.getItem(key));
              },
              checked: bind(function() {
                return !!session.getItemBind(key).get();
              })
            }), " ", R.span(bind(function() {
              return "" + (session.getItemBind(key).get());
            }))
          ]))
        ]);
      })), R.button({
        type: 'button',
        click: function() {
          return session.clear();
        }
      }, "Clear")
    ]));
  };

  init();

}).call(this);

//# sourceMappingURL=sample.js.map
