open Ava

test("Successfully parses valid data", t => {
  let schema = S.string->S.stringLength(1)

  t->Assert.deepEqual("1"->S.parseAnyWith(schema), Ok("1"), ())
})

test("Fails to parse invalid data", t => {
  let schema = S.string->S.stringLength(1)

  t->U.assertErrorResult(
    () => ""->S.parseAnyWith(schema),
    {
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
  t->U.assertErrorResult(
    () => "1234"->S.parseAnyWith(schema),
    {
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: Parse,
      path: S.Path.empty,
    },
  )
})

test("Successfully serializes valid value", t => {
  let schema = S.string->S.stringLength(1)

  t->Assert.deepEqual("1"->S.reverseConvertWith(schema), %raw(`"1"`), ())
})

test("Fails to serialize invalid value", t => {
  let schema = S.string->S.stringLength(1)

  t->U.assertRaised(
    () => ""->S.reverseConvertWith(schema),
    {
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
  t->U.assertRaised(
    () => "1234"->S.reverseConvertWith(schema),
    {
      code: OperationFailed("String must be exactly 1 characters long"),
      operation: SerializeToUnknown,
      path: S.Path.empty,
    },
  )
})

test("Returns custom error message", t => {
  let schema = S.string->S.stringLength(~message="Custom", 12)

  t->Assert.deepEqual(
    "123"->S.parseAnyWith(schema),
    Error(U.error({code: OperationFailed("Custom"), operation: Parse, path: S.Path.empty})),
    (),
  )
})

test("Returns refinement", t => {
  let schema = S.string->S.stringLength(4)

  t->Assert.deepEqual(
    schema->S.String.refinements,
    [{kind: Length({length: 4}), message: "String must be exactly 4 characters long"}],
    (),
  )
})
