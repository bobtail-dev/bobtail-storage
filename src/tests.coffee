{$, _, rxStorage} = window

# used as a prefix on storage keys to ensure that QUnit tests do not accidentally overwrite any preexisting keys.
testPrefix = "reactive__storage__test__"
storages = ["local", "session"]

TEST_OBJECT = {name: "name", array: [1,2,3], object: {a: 'a', b: 'b'}}
TEST_ARRAY = [1,2, [3,4, {name: 'name'}]]

# fun fact: window.*storage.getItem('foo') returns null if foo is a nonexistent key, whereas
# window.*storage.foo returns undefined.

storages.forEach (storage) ->
  testKey = (k) -> "#{testPrefix}#{storage}__#{k}"
  windowStorage = window["#{storage}Storage"]
  curRxStorage = rxStorage[storage]
  curRxStorage.clear()

  emptyState = {}
  emptyState[window.rxStorage.__storageTypeKey] = storage

  QUnit.test "#{storage}.addString", (assert) ->
    k = testKey("addString")
    curRxStorage.setItem(k, "value")
    assert.strictEqual curRxStorage.getItem(k), "value"
    assert.strictEqual windowStorage[k], "value"

  QUnit.test "#{storage}.addJSON", (assert) ->
    k = testKey("addJSON")
    curRxStorage.setItem k, TEST_OBJECT
    assert.propEqual curRxStorage.getItem(k), TEST_OBJECT
    assert.strictEqual windowStorage[rxStorage.__jsonPrefix k], JSON.stringify TEST_OBJECT

  QUnit.test "#{storage}.addNumber", (assert) ->
    k1 = testKey('addInt')
    k2 = testKey('addInt.0')
    k3 = testKey('addFloat')
    curRxStorage.setItem k1, 42
    curRxStorage.setItem k2, 42.000
    curRxStorage.setItem k3, 42.5

    assert.strictEqual curRxStorage.getItem(k1), 42
    assert.strictEqual curRxStorage.getItem(k2), 42
    assert.strictEqual curRxStorage.getItem(k3), 42.5

    assert.strictEqual windowStorage[rxStorage.__numberPrefix k1], "42"
    assert.strictEqual windowStorage[rxStorage.__numberPrefix k2], "42"
    assert.strictEqual windowStorage[rxStorage.__numberPrefix k3], "42.5"

  QUnit.test "#{storage}.addNull", (assert) ->
    k = testKey('addNull')
    curRxStorage.setItem k, null
    assert.strictEqual(curRxStorage.getItem(k), null)
    assert.strictEqual windowStorage[rxStorage.__nullPrefix k], "null"

  QUnit.test "#{storage}.removeNull", (assert) ->
    k = testKey('addNull')
    curRxStorage.setItem k, null
    curRxStorage.removeItem k
    assert.strictEqual(curRxStorage.getItem(k), undefined)
    assert.strictEqual windowStorage[rxStorage.__nullPrefix k], undefined

  QUnit.test "#{storage}.clear", (assert) ->
    k1 = testKey("clearString")
    k2 = testKey("clearJSON")
    curRxStorage.setItem(k1, "str")
    curRxStorage.setItem(k2, TEST_OBJECT)
    curRxStorage.clear()
    assert.strictEqual(curRxStorage.getItem(k1), undefined)
    assert.strictEqual(curRxStorage.getItem(k2), undefined)
    assert.propEqual windowStorage, emptyState

  QUnit.test "#{storage}.removeString", (assert) ->
    k = testKey("removeString")
    curRxStorage.setItem(k, "str")
    curRxStorage.removeItem(k)
    assert.strictEqual(curRxStorage.getItem(k), undefined)
    assert.propEqual windowStorage, emptyState

  QUnit.test "#{storage}.removeJSON", (assert) ->
    k = testKey("removeJSON")
    curRxStorage.setItem(k, TEST_OBJECT)
    curRxStorage.removeItem(k)
    assert.strictEqual(curRxStorage.getItem(k), undefined)
    assert.propEqual windowStorage, emptyState

  QUnit.test "#{storage}.getMissingKey", (assert) ->
    assert.strictEqual(curRxStorage.getItem(testKey "badkey"), undefined)

  QUnit.test "#{storage}.bind", (assert) ->
    k = testKey("bind")
    depCell = curRxStorage.getItemBind(k)

    snapAssert = (func, val) -> assert[func] (rx.snap -> depCell.get()), val

    assert.strictEqual((rx.snap -> depCell.get()), undefined)
    curRxStorage.setItem k, "bindstring"
    snapAssert "strictEqual", "bindstring"
    curRxStorage.setItem k, TEST_OBJECT
    snapAssert "deepEqual", TEST_OBJECT
    curRxStorage.setItem k, 42.5
    snapAssert "strictEqual", 42.5
    curRxStorage.setItem k, null
    snapAssert "strictEqual", null
    curRxStorage.setItem k, TEST_ARRAY
    snapAssert "deepEqual", TEST_ARRAY
    curRxStorage.setItem k, 42
    snapAssert "strictEqual", 42
    curRxStorage.removeItem(k)
    snapAssert "strictEqual", undefined
    curRxStorage.setItem(k, "a new bind")
    snapAssert "strictEqual", "a new bind"

  QUnit.test "#{storage}.collisions", (assert) ->
    k = testKey("collisions")
    jsonK = rxStorage.__jsonPrefix k
    curRxStorage.setItem(k, "bindstring")
    assert.strictEqual windowStorage[jsonK], undefined
    assert.strictEqual windowStorage[k], "bindstring"
    assert.strictEqual curRxStorage.getItem(k), "bindstring"

    curRxStorage.setItem(k, TEST_OBJECT)
    assert.strictEqual windowStorage[k], undefined
    assert.strictEqual windowStorage[jsonK], JSON.stringify TEST_OBJECT
    assert.deepEqual curRxStorage.getItem(k), TEST_OBJECT

    curRxStorage.setItem(k, TEST_ARRAY)
    assert.strictEqual windowStorage[k], undefined
    assert.strictEqual windowStorage[jsonK], JSON.stringify TEST_ARRAY
    assert.deepEqual curRxStorage.getItem(k), TEST_ARRAY

    curRxStorage.setItem(k, "a new bind")
    assert.strictEqual windowStorage[jsonK], undefined
    assert.strictEqual windowStorage[k], "a new bind"
    assert.strictEqual curRxStorage.getItem(k), "a new bind"

  QUnit.test "#{storage}.storageEvent", (assert) ->
    event = $.Event('storage')
    key = testKey("storageEvent")

    cell = curRxStorage.getItemBind key

    event.originalEvent = {
      storageArea: windowStorage
      key
      newValue: "42"
    }
    $(window).trigger(event)

    assert.strictEqual curRxStorage.getItem(key), "42"
    assert.strictEqual (rx.snap -> cell.get()), "42"
