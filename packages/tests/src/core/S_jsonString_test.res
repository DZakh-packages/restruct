open Ava
open RescriptCore

test("Successfully parses JSON", t => {
  let struct = S.string

  t->Assert.deepEqual(`"Foo"`->S.parseAnyWith(S.jsonString(struct)), Ok("Foo"), ())
})

test("Successfully serializes JSON", t => {
  let struct = S.string

  t->Assert.deepEqual(
    `Foo`->S.serializeToUnknownWith(S.jsonString(struct)),
    Ok(%raw(`'"Foo"'`)),
    (),
  )
})

test("Fails to create struct when passing non-jsonable struct to S.jsonString", t => {
  t->Assert.throws(
    () => {
      S.jsonString(S.object(s => s.field("foo", S.unknown)))
    },
    ~expectations={
      message: `[rescript-struct] The struct Object({"foo": Unknown}) passed to S.jsonString is not compatible with JSON`,
    },
    (),
  )
})

test("Compiled parse code snapshot", t => {
  let struct = S.jsonString(S.bool)

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0;if(typeof i!=="string"){e[2](i)}try{v0=JSON.parse(i)}catch(t){e[0](t.message)}if(typeof v0!=="boolean"){e[1](v0)}return v0}`,
  )
})

test("Compiled async parse code snapshot", t => {
  let struct = S.jsonString(S.bool->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

  t->U.assertCompiledCode(
    ~struct,
    ~op=#parse,
    `i=>{let v0,v1;if(typeof i!=="string"){e[3](i)}try{v0=JSON.parse(i)}catch(t){e[0](t.message)}if(typeof v0!=="boolean"){e[1](v0)}v1=e[2](v0);return v1}`,
  )
})

test("Compiled serialize code snapshot", t => {
  let struct = S.jsonString(S.bool)

  t->U.assertCompiledCode(~struct, ~op=#serialize, `i=>{return JSON.stringify(i)}`)
})