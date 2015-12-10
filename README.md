# reactive-storage

reactive-storage is a simple library integrating [reactive-coffee](http://yang.github.io/reactive-coffee/) with the
[HTML5 Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API). reactive-storage exposes two
objects, `rxStorage.local` and `rxStorage.session`, which map to `window.localStorage` and `window.sessionStorage`,
respectively. Under the hood, these are powered by two reactive
[SrcMap objects](http://yang.github.io/reactive-coffee/api.html#rx-namespace).

In addition, reactive-storage automatically serializes and deserializes numbers, booleans, nulls, and JSON objects and arrays for storage and retrieval.

## Installation
To install reactive-storage, simply run `bower install reactive-storage`.

## API
Both `rxStorage.local` and `rxStorage.session` have the same API. Each supports the following methods from the
[Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Storage).
The only difference is that, unlike with the web storage API, these methods work with JSON objects.
That is, you can store and retrieve arrays and objects, and reactive-storage will automatically handle serializing and
deserializing for you.

### getItem(k)
getItem is safe to call outside of a reactive bind context, as it wraps the underlying call in an
`rx.snap`.
### setItem(k, v)
### removeItem(k)
### clear()

### getItemBind
This is the most important function in reactive-storage. Whereas getItem returns the value stored in `k`,
getItemBind returns an `rx.DepCell` bound to the value stored in `k`. This means that if the value stored in k changes,
the DepCell will automatically update.

```
    userCell = window.rxStorage.session.getItemBind 'username'
    rx.autoSub userCell.onSet, ([o, n]) ->
        s = ""
        if o then s += "Goodbye, #{o}! "
        if n then s += "Welcome, #{n}!"
        if s then alert s
    window.rxStorage.session.setItem 'username', 'Joe'
    # output: "Welcome, Joe!"
    window.rxStorage.session.setItem 'username', 'Fred'
    # output: "Goodbye, Joe! Welcome, Fred!"
    window.rxStorage.session.setItem 'username', 'Bob'
    # output: "Goodbye, Fred! Welcome, Bob!"
    window.rxStorage.session.removeItem 'username'
    # output: "Goodbye, Bob! "
```

If the item is removed, the value of the DepCell is set to `undefined`.

### Listeners
In addition, the storage objects expose the `onAdd`, `onRemove`, and `onChange` events from their underlying
`SrcMap` objects, allowing you to add listeners to these events:

```
    rx.autoSub window.rxStorage.session.onAdd, ([k, n]) -> alert "Added #{k}: #{v} to session storage!"
    window.rxStorage.session.addItem("answer", 42)
    # output: "Added answer: 42 to session storage!"
```

### Storage events

The Web storage API [supports events](https://developer.mozilla.org/en-US/docs/Web/API/StorageEvent) for storage
changes from other browser tabs. ***These events are not currently supported by reactive-storage.***

## Creator

**Richard Mehlinger**

- <https://twitter.com/rmehlinger>
- <https://github.com/rmehlinger>


## Copyright and license

Code and docs released under [the MIT license](https://github.com/twbs/bootstrap/blob/master/LICENSE).
