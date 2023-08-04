open Ava

test("OperationFailed error", t => {
  t->Assert.is(
    {
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    "Failed parsing at root. Reason: Should be positive",
    (),
  )
})

test("Error with Serializing operation", t => {
  t->Assert.is(
    {
      code: OperationFailed("Should be positive"),
      operation: Serializing,
      path: S.Path.empty,
    }->S.Error.toString,
    "Failed serializing at root. Reason: Should be positive",
    (),
  )
})

test("Error with path", t => {
  t->Assert.is(
    {
      code: OperationFailed("Should be positive"),
      operation: Parsing,
      path: S.Path.fromArray(["0", "foo"]),
    }->S.Error.toString,
    `Failed parsing at ["0"]["foo"]. Reason: Should be positive`,
    (),
  )
})

test("InvalidOperation error", t => {
  t->Assert.is(
    {
      code: InvalidOperation({description: "The S.transform serializer is missing"}),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    "Failed parsing at root. Reason: The S.transform serializer is missing",
    (),
  )
})

test("InvalidType error", t => {
  t->Assert.is(
    {
      code: InvalidType({expected: S.string->S.toUnknown, received: Obj.magic(true)}),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    "Failed parsing at root. Reason: Expected String, received true",
    (),
  )
})

test("UnexpectedAsync error", t => {
  t->Assert.is(
    {
      code: UnexpectedAsync,
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    "Failed parsing at root. Reason: Encountered unexpected asynchronous transform or refine. Use S.parseAsyncWith instead of S.parseWith",
    (),
  )
})

test("InvalidLiteral error", t => {
  t->Assert.is(
    {
      code: InvalidLiteral({expected: Boolean(false), received: true->Obj.magic}),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    "Failed parsing at root. Reason: Expected false, received true",
    (),
  )
})

test("ExcessField error", t => {
  t->Assert.is(
    {
      code: ExcessField("unknownKey"),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    `Failed parsing at root. Reason: Encountered disallowed excess key "unknownKey" on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`,
    (),
  )
})

test("InvalidTupleSize error", t => {
  t->Assert.is(
    {
      code: InvalidTupleSize({expected: 1, received: 2}),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    `Failed parsing at root. Reason: Expected Tuple with 1 items, received 2`,
    (),
  )
})

test("InvalidUnion error", t => {
  t->Assert.is(
    {
      code: InvalidUnion([
        {
          code: InvalidLiteral({expected: String("circle"), received: "oval"->Obj.magic}),
          operation: Parsing,
          path: S.Path.fromArray(["kind"]),
        },
        {
          code: InvalidLiteral({expected: String("square"), received: "oval"->Obj.magic}),
          operation: Parsing,
          path: S.Path.fromArray(["kind"]),
        },
        {
          code: InvalidLiteral({expected: String("triangle"), received: "oval"->Obj.magic}),
          operation: Parsing,
          path: S.Path.fromArray(["kind"]),
        },
      ]),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    `Failed parsing at root. Reason: Invalid union with following errors
- Failed at ["kind"]. Expected "circle", received "oval"
- Failed at ["kind"]. Expected "square", received "oval"
- Failed at ["kind"]. Expected "triangle", received "oval"`,
    (),
  )
})

test("InvalidUnion filters similar reasons", t => {
  t->Assert.is(
    {
      code: InvalidUnion([
        {
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parsing,
          path: S.Path.empty,
        },
        {
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parsing,
          path: S.Path.empty,
        },
        {
          code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
          operation: Parsing,
          path: S.Path.empty,
        },
      ]),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    `Failed parsing at root. Reason: Invalid union with following errors
- Expected Bool, received "Hello world!"`,
    (),
  )
})

test("Nested InvalidUnion error", t => {
  t->Assert.is(
    {
      code: InvalidUnion([
        {
          code: InvalidUnion([
            {
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parsing,
              path: S.Path.empty,
            },
            {
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parsing,
              path: S.Path.empty,
            },
            {
              code: InvalidType({expected: S.bool->S.toUnknown, received: %raw(`"Hello world!"`)}),
              operation: Parsing,
              path: S.Path.empty,
            },
          ]),
          operation: Parsing,
          path: S.Path.empty,
        },
      ]),
      operation: Parsing,
      path: S.Path.empty,
    }->S.Error.toString,
    `Failed parsing at root. Reason: Invalid union with following errors
- Invalid union with following errors
  - Expected Bool, received "Hello world!"`,
    (),
  )
})

test("InvalidJsonStruct error", t => {
  t->Assert.is(
    {
      code: InvalidJsonStruct(S.option(S.literal(true))->S.toUnknown),
      operation: Serializing,
      path: S.Path.empty,
    }->S.Error.toString,
    `Failed serializing at root. Reason: The struct Option(Literal(true)) is not compatible with JSON`,
    (),
  )
})