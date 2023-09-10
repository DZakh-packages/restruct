open Ava
open RescriptCore

test("Returns false for struct with NoOperation", t => {
  t->Assert.is(S.unknown->S.isAsyncParse, false, ())
})

test("Returns false for sync struct", t => {
  t->Assert.is(S.string->S.isAsyncParse, false, ())
})

test("Returns true for async struct", t => {
  let struct = S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)})

  t->Assert.is(struct->S.isAsyncParse, true, ())
})

test("Returns true for async struct after running a serializer", t => {
  let struct =
    S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i), serializer: i => i})
  t->Assert.deepEqual("abc"->S.serializeWith(struct), Ok(%raw(`"abc"`)), ())
  t->Assert.is(struct->S.isAsyncParse, true, ())
})

test("Returns true for struct with nested async", t => {
  let struct = S.tuple1(S.string->S.transform(_ => {asyncParser: i => () => Promise.resolve(i)}))

  t->Assert.is(struct->S.isAsyncParse, true, ())
})