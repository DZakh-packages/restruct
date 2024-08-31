open Ava

module Common = {
  let any = %raw(`"Hello world!"`)
  let factory = () => S.unknown

  test("Successfully parses", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.parseAnyWith(schema), Ok(any), ())
  })

  test("Successfully serializes", t => {
    let schema = factory()

    t->Assert.deepEqual(any->S.serializeToUnknownWith(schema), Ok(any), ())
  })

  test("Compiled parse code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCodeIsNoop(~schema, ~op=#Parse)
  })

  test("Compiled serialize code snapshot", t => {
    let schema = factory()

    t->U.assertCompiledCodeIsNoop(~schema, ~op=#Serialize)
  })

  test("Reverse schema to self", t => {
    let schema = factory()

    t->Assert.is(schema->S.reverse, schema->S.toUnknown, ())
  })
}

test("Doesn't return refinements", t => {
  let schema = S.unknown
  t->Assert.deepEqual(schema->S.String.refinements, [], ())
  t->Assert.deepEqual(schema->S.Array.refinements, [], ())
  t->Assert.deepEqual(schema->S.Int.refinements, [], ())
  t->Assert.deepEqual(schema->S.Float.refinements, [], ())
})
