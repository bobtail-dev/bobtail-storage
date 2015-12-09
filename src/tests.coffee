{$, _, rxStorage} = window

# used as a prefix on storage keys to ensure that QUnit tests do not accidentally overwrite any preexisting keys.
testPrefix = "reactive__storage__test__"
testKey = (k) -> "#{testPrefix}#{k}"
storages = ["localStorage", "sessionStorage"]

TEST_OBJECT = {name: "name", array: [1,2,3], object: {a: 'a', b: 'b'}}
TEST_ARRAY = [1,2, [3,4, {name: 'name'}]]

storages.forEach (storage) ->
  curRxStorage = rxStorage[storage]
  windowStorage = window[storage]
  windowStorage.clear()

  QUnit.test "#{storage}.addString", (assert) ->
    k = testKey("addString")
    curRxStorage.setItem(k, "value")
    assert.equal curRxStorage.getItem(k), "value"
    assert.equal windowStorage[k], "value"

  QUnit.test "#{storage}.addJSON", (assert) ->
    k = testKey("addJSON")
    curRxStorage.setItem k, TEST_OBJECT
    assert.propEqual curRxStorage.getItem(k), TEST_OBJECT
    assert.equal windowStorage.getItem("#{rxStorage.__jsonPrefix}#{k}"), JSON.stringify TEST_OBJECT

  QUnit.test "#{storage}.clear", (assert) ->
    k1 = testKey("clearString")
    k2 = testKey("clearJSON")
    curRxStorage.setItem(k1, "str")
    curRxStorage.setItem(k2, TEST_OBJECT)
    curRxStorage.clear()
    assert.strictEqual(curRxStorage.getItem(k1), undefined)
    assert.strictEqual(curRxStorage.getItem(k2), undefined)
    assert.propEqual windowStorage, {}

  QUnit.test "#{storage}.removeString", (assert) ->
    k = testKey("clearString")
    curRxStorage.setItem(k, "str")
    curRxStorage.removeItem(k)
    assert.strictEqual(curRxStorage.getItem(k), undefined)
    assert.propEqual windowStorage, {}

  QUnit.test "#{storage}.removeJSON", (assert) ->
    k = testKey("clearString")
    curRxStorage.setItem(k, TEST_OBJECT)
    curRxStorage.removeItem(k)
    assert.strictEqual(curRxStorage.getItem(k), undefined)
    assert.propEqual windowStorage, {}

  QUnit.test "#{storage}.getMissingKey", (assert) ->
    assert.strictEqual(curRxStorage.getItem("badkey"), undefined)
