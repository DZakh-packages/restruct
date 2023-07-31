module Suite = {
  module BenchmarkResult = {
    type t

    @send
    external toString: t => string = "toString"
  }

  type t
  type event = {target: BenchmarkResult.t}

  @module("benchmark") @scope("default") @new
  external make: unit => t = "Suite"

  @send
  external add: (t, string, unit => 'a) => t = "add"

  let addWithPrepare = (suite, name, fn) => {
    suite->add(name, fn())
  }

  @send
  external _onCycle: (t, @as(json`"cycle"`) _, event => unit) => t = "on"

  @send
  external _run: t => unit = "run"

  let run = suite => {
    suite
    ->_onCycle(event => {
      Js.log(event.target->BenchmarkResult.toString)
    })
    ->_run
  }
}

let makeTestObject = () => {
  %raw(`Object.freeze({
    number: 1,
    negNumber: -1,
    maxNumber: Number.MAX_VALUE,
    string: 'string',
    longString:
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
    boolean: true,
    deeplyNested: {
      foo: 'bar',
      num: 1,
      bool: false,
    },
  })`)
}

let makeAdvancedObjectStruct = () => {
  S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(s =>
          {
            "foo": s.field("foo", S.string),
            "num": s.field("num", S.float),
            "bool": s.field("bool", S.bool),
          }
        ),
      ),
    }
  )
}

let makeAdvancedStrictObjectStruct = () => {
  S.object(s =>
    {
      "number": s.field("number", S.float),
      "negNumber": s.field("negNumber", S.float),
      "maxNumber": s.field("maxNumber", S.float),
      "string": s.field("string", S.string),
      "longString": s.field("longString", S.string),
      "boolean": s.field("boolean", S.bool),
      "deeplyNested": s.field(
        "deeplyNested",
        S.object(s =>
          {
            "foo": s.field("foo", S.string),
            "num": s.field("num", S.float),
            "bool": s.field("bool", S.bool),
          }
        )->S.Object.strict,
      ),
    }
  )->S.Object.strict
}

let data = makeTestObject()
Js.Console.timeStart("init")
let struct = makeAdvancedObjectStruct()
Js.Console.timeEnd("init")
Js.Console.timeStart("p: 1")
data->S.parseAnyWith(struct)->ignore
Js.Console.timeEnd("p: 1")
Js.Console.timeStart("p: 2")
data->S.parseAnyWith(struct)->ignore
Js.Console.timeEnd("p: 2")
Js.Console.timeStart("p: 3")
data->S.parseAnyWith(struct)->ignore
Js.Console.timeEnd("p: 3")
Js.Console.timeStart("s: 1")
data->S.serializeWith(struct)->ignore
Js.Console.timeEnd("s: 1")
Js.Console.timeStart("s: 2")
data->S.serializeWith(struct)->ignore
Js.Console.timeEnd("s: 2")
Js.Console.timeStart("s: 3")
data->S.serializeWith(struct)->ignore
Js.Console.timeEnd("s: 3")

Suite.make()
->Suite.addWithPrepare("Parse string", () => {
  let struct = S.string
  let data = "Hello world!"
  () => {
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Serialize string", () => {
  let struct = S.string
  let data = "Hello world!"
  () => {
    data->S.serializeOrRaiseWith(struct)
  }
})
->Suite.add("Advanced object struct factory", makeAdvancedObjectStruct)
->Suite.addWithPrepare("Parse advanced object", () => {
  let struct = makeAdvancedObjectStruct()
  let data = makeTestObject()
  () => {
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Create and parse advanced object", () => {
  let data = makeTestObject()
  () => {
    let struct = makeAdvancedObjectStruct()
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Parse advanced strict object", () => {
  let struct = makeAdvancedStrictObjectStruct()
  let data = makeTestObject()
  () => {
    data->S.parseAnyOrRaiseWith(struct)
  }
})
->Suite.addWithPrepare("Serialize advanced object", () => {
  let struct = makeAdvancedObjectStruct()
  let data = makeTestObject()
  () => {
    data->S.serializeOrRaiseWith(struct)
  }
})
->Suite.run