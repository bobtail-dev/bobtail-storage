{$, _, rxStorage} = window

# used as a prefix on storage keys to ensure that QUnit tests do not accidentally overwrite any preexisting keys.
testPrefix = "reactive__storage__test__"
storages = ["localStorage", "sessionStorage"]

TEST_OBJECT = {name: "name", array: [1,2,3], object: {a: 'a', b: 'b'}}
TEST_ARRAY = [1,2, [3,4, {name: 'name'}]]

storages.forEach (storage) ->
  testKey = (k) -> "#{testPrefix}#{storage}__#{k}"
  curRxStorage = rxStorage[storage]
  windowStorage = window[storage]
  windowStorage.clear()

  QUnit.test "#{storage}.addString", (assert) ->
    k = testKey("addString")
    curRxStorage.setItem(k, "value")
    assert.equal curRxStorage.snapGetItem(k), "value"
    assert.equal windowStorage[k], "value"

  QUnit.test "#{storage}.addJSON", (assert) ->
    k = testKey("addJSON")
    curRxStorage.setItem k, TEST_OBJECT
    assert.propEqual curRxStorage.snapGetItem(k), TEST_OBJECT
    assert.equal windowStorage.getItem(rxStorage.__jsonPrefix k), JSON.stringify TEST_OBJECT

  QUnit.test "#{storage}.clear", (assert) ->
    k1 = testKey("clearString")
    k2 = testKey("clearJSON")
    curRxStorage.setItem(k1, "str")
    curRxStorage.setItem(k2, TEST_OBJECT)
    curRxStorage.clear()
    assert.strictEqual(curRxStorage.snapGetItem(k1), undefined)
    assert.strictEqual(curRxStorage.snapGetItem(k2), undefined)
    assert.propEqual windowStorage, {}

  QUnit.test "#{storage}.removeString", (assert) ->
    k = testKey("clearString")
    curRxStorage.setItem(k, "str")
    curRxStorage.removeItem(k)
    assert.strictEqual(curRxStorage.snapGetItem(k), undefined)
    assert.propEqual windowStorage, {}

  QUnit.test "#{storage}.removeJSON", (assert) ->
    k = testKey("clearString")
    curRxStorage.setItem(k, TEST_OBJECT)
    curRxStorage.removeItem(k)
    assert.strictEqual(curRxStorage.snapGetItem(k), undefined)
    assert.propEqual windowStorage, {}

  QUnit.test "#{storage}.getMissingKey", (assert) ->
    assert.strictEqual(curRxStorage.snapGetItem("badkey"), undefined)

  QUnit.test "#{storage}.bind", (assert) ->
    k = testKey("bind")
    depCell = rx.bind -> curRxStorage.getItem(k)
    assert.strictEqual((rx.snap -> depCell.get()), undefined)
    curRxStorage.setItem(k, "bindstring")
    assert.equal((rx.snap -> depCell.get()), "bindstring")
    curRxStorage.setItem(k, TEST_OBJECT)
    assert.deepEqual((rx.snap -> depCell.get()), TEST_OBJECT)
    curRxStorage.setItem(k, TEST_ARRAY)
    assert.deepEqual((rx.snap -> depCell.get()), TEST_ARRAY)
    curRxStorage.setItem(k, "a new bind")
    assert.equal((rx.snap -> depCell.get()), "a new bind")
    curRxStorage.removeItem(k)
    assert.strictEqual((rx.snap -> depCell.get()), undefined)

  QUnit.test "#{storage}.collisions", (assert) ->
    k = testKey("collisions")
    jsonK = rxStorage.__jsonPrefix k
    curRxStorage.setItem(k, "bindstring")
    assert.strictEqual windowStorage[jsonK], undefined
    assert.equal windowStorage[k], "bindstring"
    assert.equal curRxStorage.snapGetItem(k), "bindstring"

    curRxStorage.setItem(k, TEST_OBJECT)
    assert.strictEqual windowStorage[k], undefined
    assert.equal windowStorage[jsonK], JSON.stringify TEST_OBJECT
    assert.deepEqual curRxStorage.snapGetItem(k), TEST_OBJECT

    curRxStorage.setItem(k, TEST_ARRAY)
    assert.strictEqual windowStorage[k], undefined
    assert.equal windowStorage[jsonK], JSON.stringify TEST_ARRAY
    assert.deepEqual curRxStorage.snapGetItem(k), TEST_ARRAY

    curRxStorage.setItem(k, "a new bind")
    assert.strictEqual windowStorage[jsonK], undefined
    assert.equal windowStorage[k], "a new bind"
    assert.equal curRxStorage.snapGetItem(k), "a new bind"
