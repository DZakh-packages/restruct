open Ava

test("Doesn't affect valid parsing", t => {
  let struct = S.string->S.catch(_ => "fallback")

  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok("abc"), ())
})

test("Doesn't do anything with unknown struct", t => {
  let struct = S.unknown->S.catch(_ => %raw(`"fallback"`))

  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok(%raw(`"abc"`)), ())
})

test("Uses fallback value when parsing failed", t => {
  let struct = S.string->S.catch(_ => "fallback")

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("fallback"), ())
})

test("Doesn't affect serializing in any way", t => {
  let struct = S.literal("123")->S.catch(_ => "fallback")

  t->Assert.deepEqual(
    "abc"->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidLiteral({received: "abc"->Obj.magic, expected: String("123")}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

test("Provides ctx to use in catch", t => {
  t->ExecutionContext.plan(3)
  let struct = S.string->S.catch(s => {
    t->Assert.deepEqual(
      s.error,
      {
        code: InvalidType({received: %raw(`123`), expected: S.string->S.toUnknown}),
        operation: Parsing,
        path: S.Path.empty,
      },
      (),
    )
    t->Assert.deepEqual(s.input, %raw(`123`), ())
    "fallback"
  })

  t->Assert.deepEqual(123->S.parseAnyWith(struct), Ok("fallback"), ())
})

test("Can use s.fail inside of S.catch", t => {
  let struct = S.literal("0")->S.catch(s => {
    switch s.input->S.parseAnyWith(S.string) {
    | Ok(_) => "1"
    | Error(_) => s.fail("Fallback value only supported for strings.")
    }
  })

  t->Assert.deepEqual("0"->S.parseAnyWith(struct), Ok("0"), ())
  t->Assert.deepEqual("abc"->S.parseAnyWith(struct), Ok("1"), ())
  t->Assert.deepEqual(
    123->S.parseAnyWith(struct),
    Error({
      code: OperationFailed("Fallback value only supported for strings."),
      operation: Parsing,
      path: S.Path.empty,
    }),
    (),
  )
  t->Assert.deepEqual("0"->S.serializeToUnknownWith(struct), Ok(%raw(`"0"`)), ())
  t->Assert.deepEqual(
    "1"->S.serializeToUnknownWith(struct),
    Error({
      code: InvalidLiteral({expected: String("0"), received: "1"->Obj.magic}),
      operation: Serializing,
      path: S.Path.empty,
    }),
    (),
  )
})

asyncTest("Uses fallback value when async struct parsing failed during the sync part", async t => {
  let struct = S.string->S.asyncParserRefine(_ => _ => Promise.resolve())->S.catch(_ => "fallback")

  t->Assert.deepEqual(await 123->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
})

asyncTest("Uses fallback value when async struct parsing failed during the async part", async t => {
  let struct = S.string->S.asyncParserRefine(s => _ => s.fail("fail"))->S.catch(_ => "fallback")

  t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
})

asyncTest(
  "Uses fallback value when async struct parsing failed during the async part in promise",
  async t => {
    let struct =
      S.string
      ->S.asyncParserRefine(s => _ => Promise.resolve()->Promise.thenResolve(() => s.fail("fail")))
      ->S.catch(_ => "fallback")

    t->Assert.deepEqual(await "123"->S.parseAnyAsyncWith(struct), Ok("fallback"), ())
  },
)