open Ava

@live
type options = {fast?: bool, mode?: int}

test("Successfully parses object with inlinable string field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: "bar"}`)->S.parseWith(struct), Ok({"field": "bar"}), ())
})

test("Fails to parse object with inlinable string field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "String", received: "Float"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable bool field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.bool()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: true}`)->S.parseWith(struct), Ok({"field": true}), ())
})

test("Fails to parse object with inlinable bool field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.bool()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Bool", received: "Float"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable date field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.date()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: new Date("2015-12-12")}`)->S.parseWith(struct),
    Ok({"field": Js.Date.fromString("2015-12-12")}),
    (),
  )
})

test("Fails to parse object with inlinable date field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.date()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: 123}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Date", received: "Float"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable unknown field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.unknown()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: new Date("2015-12-12")}`)->S.parseWith(struct),
    Ok(%raw(`{field: new Date("2015-12-12")}`)),
    (),
  )
})

test("Fails to parse object with inlinable never field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.never()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Never", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable float field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.float()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseWith(struct), Ok({"field": 123.}), ())
})

test("Fails to parse object with inlinable float field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.float()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Float", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with inlinable int field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.int()),
    }
  )

  t->Assert.deepEqual(%raw(`{field: 123}`)->S.parseWith(struct), Ok({"field": 123}), ())
})

test("Fails to parse object with inlinable int field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.int()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Int", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Successfully parses object with not inlinable empty object field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.object(_ => ())),
    }
  )

  t->Assert.deepEqual(%raw(`{field: {}}`)->S.parseWith(struct), Ok({"field": ()}), ())
})

test("Fails to parse object with not inlinable empty object field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.object(_ => ())),
    }
  )

  t->Assert.deepEqual(
    %raw(`{field: true}`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Object", received: "Bool"}),
      operation: Parsing,
      path: ["field"],
    }),
    (),
  )
})

test("Fails to parse object when provided invalid data", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`12`)->S.parseWith(struct),
    Error({
      code: UnexpectedType({expected: "Object", received: "Float"}),
      operation: Parsing,
      path: [],
    }),
    (),
  )
})

test("Successfully serializes object with single field", t => {
  let struct = S.object(o =>
    {
      "field": o->S.field("field", S.string()),
    }
  )

  t->Assert.deepEqual({"field": "bar"}->S.serializeWith(struct), Ok(%raw(`{field: "bar"}`)), ())
})

test("Successfully parses object with multiple fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field("boo", S.string()),
      "zoo": o->S.field("zoo", S.string()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar", zoo: "jee"}`)->S.parseWith(struct),
    Ok({"boo": "bar", "zoo": "jee"}),
    (),
  )
})

test("Successfully serializes object with multiple fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field("boo", S.string()),
      "zoo": o->S.field("zoo", S.string()),
    }
  )

  t->Assert.deepEqual(
    {"boo": "bar", "zoo": "jee"}->S.serializeWith(struct),
    Ok(%raw(`{boo: "bar", zoo: "jee"}`)),
    (),
  )
})

test("Successfully parses object with transformed field", t => {
  let struct = S.object(o =>
    {
      "string": o->S.field(
        "string",
        S.string()->S.transform(~parser=string => string ++ "field", ()),
      ),
    }
  )

  t->Assert.deepEqual(%raw(`{string: "bar"}`)->S.parseWith(struct), Ok({"string": "barfield"}), ())
})

test("Fails to parse object when transformed field has raises error", t => {
  let struct = S.object(o =>
    {
      "string": o->S.field(
        "string",
        S.string()->S.transform(~parser=_ => S.Error.raise("User error"), ()),
      ),
    }
  )

  t->Assert.deepEqual(
    {"string": "bar"}->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: ["string"],
    }),
    (),
  )
})

test("Shows transformed object field name in error path when fails to parse", t => {
  let struct = S.object(o =>
    {
      "transformedFieldName": o->S.field(
        "originalFieldName",
        S.string()->S.transform(~parser=_ => S.Error.raise("User error"), ()),
      ),
    }
  )

  t->Assert.deepEqual(
    {"originalFieldName": "bar"}->S.parseWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Parsing,
      path: ["originalFieldName"],
    }),
    (),
  )
})

test("Successfully serializes object with transformed field", t => {
  let struct = S.object(o =>
    {
      "string": o->S.field(
        "string",
        S.string()->S.transform(~serializer=string => string ++ "field", ()),
      ),
    }
  )

  t->Assert.deepEqual(
    {"string": "bar"}->S.serializeWith(struct),
    Ok(%raw(`{"string": "barfield"}`)),
    (),
  )
})

test("Fails to serializes object when transformed field has raises error", t => {
  let struct = S.object(o =>
    {
      "string": o->S.field(
        "string",
        S.string()->S.transform(~serializer=_ => S.Error.raise("User error"), ()),
      ),
    }
  )

  t->Assert.deepEqual(
    {"string": "bar"}->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: ["string"],
    }),
    (),
  )
})

test("Shows transformed object field name in error path when fails to serializes", t => {
  let struct = S.object(o =>
    {
      "transformedFieldName": o->S.field(
        "originalFieldName",
        S.string()->S.transform(~serializer=_ => S.Error.raise("User error"), ()),
      ),
    }
  )

  t->Assert.deepEqual(
    {"transformedFieldName": "bar"}->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: ["transformedFieldName"],
    }),
    (),
  )
})

test("Shows transformed to nested object field name in error path when fails to serializes", t => {
  let struct = S.object(o =>
    {
      "v1": {
        "transformedFieldName": o->S.field(
          "originalFieldName",
          S.string()->S.transform(~serializer=_ => S.Error.raise("User error"), ()),
        ),
      },
    }
  )

  t->Assert.deepEqual(
    {
      "v1": {
        "transformedFieldName": "bar",
      },
    }->S.serializeWith(struct),
    Error({
      code: OperationFailed("User error"),
      operation: Serializing,
      path: ["v1", "transformedFieldName"],
    }),
    (),
  )
})

test("Successfully parses object with optional fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field("boo", S.option(S.string())),
      "zoo": o->S.field("zoo", S.option(S.string())),
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: "bar"}`)->S.parseWith(struct),
    Ok({"boo": Some("bar"), "zoo": None}),
    (),
  )
})

test("Successfully serializes object with optional fields", t => {
  let struct = S.object(o =>
    {
      "boo": o->S.field("boo", S.option(S.string())),
      "zoo": o->S.field("zoo", S.option(S.string())),
    }
  )

  t->Assert.deepEqual(
    {"boo": Some("bar"), "zoo": None}->S.serializeWith(struct),
    Ok(%raw(`{boo: "bar", zoo: undefined}`)),
    (),
  )
})

test(
  "Successfully parses object with optional fields using (?). The optinal field becomes undefined instead of beeing missing",
  t => {
    let optionsStruct = S.object(o => {
      {
        fast: ?o->S.field("fast", S.option(S.bool())),
        mode: o->S.field("mode", S.int()),
      }
    })

    t->Assert.deepEqual(
      %raw(`{mode: 1}`)->S.parseWith(optionsStruct),
      Ok({
        fast: %raw("undefined"),
        mode: 1,
      }),
      (),
    )
  },
)

test("Successfully serializes object with optional fields using (?)", t => {
  let optionsStruct = S.object(o => {
    {
      fast: ?o->S.field("fast", S.option(S.bool())),
      mode: o->S.field("mode", S.int()),
    }
  })

  t->Assert.deepEqual(
    {mode: 1}->S.serializeWith(optionsStruct),
    Ok(%raw(`{mode: 1, fast: undefined}`)),
    (),
  )
})

test("Successfully parses object with mapped field names", t => {
  let struct = S.object(o =>
    {
      "name": o->S.field("Name", S.string()),
      "email": o->S.field("Email", S.string()),
      "age": o->S.field("Age", S.int()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)->S.parseWith(struct),
    Ok({"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}),
    (),
  )
})

test("Successfully serializes object with mapped field", t => {
  let struct = S.object(o =>
    {
      "name": o->S.field("Name", S.string()),
      "email": o->S.field("Email", S.string()),
      "age": o->S.field("Age", S.int()),
    }
  )

  t->Assert.deepEqual(
    {"name": "Dmitry", "email": "dzakh.dev@gmail.com", "age": 21}->S.serializeWith(struct),
    Ok(%raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)),
    (),
  )
})

test("Successfully parses object transformed to tuple", t => {
  let struct = S.object(o => (o->S.field("boo", S.int()), o->S.field("zoo", S.int())))

  t->Assert.deepEqual(%raw(`{boo: 1, zoo: 2}`)->S.parseWith(struct), Ok(1, 2), ())
})

test("Successfully serializes object transformed to tuple", t => {
  let struct = S.object(o => (o->S.field("boo", S.int()), o->S.field("zoo", S.int())))

  t->Assert.deepEqual((1, 2)->S.serializeWith(struct), Ok(%raw(`{boo: 1, zoo: 2}`)), ())
})

test("Successfully parses object transformed to nested object", t => {
  let struct = S.object(o =>
    {
      "v1": {
        "boo": o->S.field("boo", S.int()),
        "zoo": o->S.field("zoo", S.int()),
      },
    }
  )

  t->Assert.deepEqual(
    %raw(`{boo: 1, zoo: 2}`)->S.parseWith(struct),
    Ok({"v1": {"boo": 1, "zoo": 2}}),
    (),
  )
})

test("Successfully serializes object transformed to nested object", t => {
  let struct = S.object(o =>
    {
      "v1": {
        "boo": o->S.field("boo", S.int()),
        "zoo": o->S.field("zoo", S.int()),
      },
    }
  )

  t->Assert.deepEqual(
    {"v1": {"boo": 1, "zoo": 2}}->S.serializeWith(struct),
    Ok(%raw(`{boo: 1, zoo: 2}`)),
    (),
  )
})

test("Successfully parses object transformed to nested tuple", t => {
  let struct = S.object(o =>
    {
      "v1": (o->S.field("boo", S.int()), o->S.field("zoo", S.int())),
    }
  )

  t->Assert.deepEqual(%raw(`{boo: 1, zoo: 2}`)->S.parseWith(struct), Ok({"v1": (1, 2)}), ())
})

test("Successfully serializes object transformed to nested tuple", t => {
  let struct = S.object(o =>
    {
      "v1": (o->S.field("boo", S.int()), o->S.field("zoo", S.int())),
    }
  )

  t->Assert.deepEqual({"v1": (1, 2)}->S.serializeWith(struct), Ok(%raw(`{boo: 1, zoo: 2}`)), ())
})

test("Successfully parses object with only one field returned from transformer", t => {
  let struct = S.object(o => o->S.field("field", S.bool()))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseWith(struct), Ok(true), ())
})

test("Successfully serializes object with only one field returned from transformer", t => {
  let struct = S.object(o => o->S.field("field", S.bool()))

  t->Assert.deepEqual(true->S.serializeWith(struct), Ok(%raw(`{"field": true}`)), ())
})

test("Successfully parses object transformed to the one with hardcoded fields", t => {
  let struct = S.object(o =>
    {
      "hardcoded": false,
      "field": o->S.field("field", S.bool()),
    }
  )

  t->Assert.deepEqual(
    %raw(`{"field": true}`)->S.parseWith(struct),
    Ok({
      "hardcoded": false,
      "field": true,
    }),
    (),
  )
})

test("Successfully serializes object transformed to the one with hardcoded fields", t => {
  let struct = S.object(o =>
    {
      "hardcoded": false,
      "field": o->S.field("field", S.bool()),
    }
  )

  t->Assert.deepEqual(
    {
      "hardcoded": false,
      "field": true,
    }->S.serializeWith(struct),
    Ok(%raw(`{"field": true}`)),
    (),
  )
})

test("Successfully parses object transformed to variant", t => {
  let struct = S.object(o => #VARIANT(o->S.field("field", S.bool())))

  t->Assert.deepEqual(%raw(`{"field": true}`)->S.parseWith(struct), Ok(#VARIANT(true)), ())
})

test("Successfully serializes object transformed to variant", t => {
  let struct = S.object(o => #VARIANT(o->S.field("field", S.bool())))

  t->Assert.deepEqual(#VARIANT(true)->S.serializeWith(struct), Ok(%raw(`{"field": true}`)), ())
})

test("Successfully parses object from benchmark", t => {
  let struct = S.object(o =>
    {
      "number": o->S.field("number", S.float()),
      "negNumber": o->S.field("negNumber", S.float()),
      "maxNumber": o->S.field("maxNumber", S.float()),
      "string": o->S.field("string", S.string()),
      "longString": o->S.field("longString", S.string()),
      "boolean": o->S.field("boolean", S.bool()),
      "deeplyNested": o->S.field(
        "deeplyNested",
        S.object(
          o =>
            {
              "foo": o->S.field("foo", S.string()),
              "num": o->S.field("num", S.float()),
              "bool": o->S.field("bool", S.bool()),
            },
        ),
      ),
    }
  )

  t->Assert.deepEqual(
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
    })`)->S.parseWith(struct),
    Ok({
      "number": 1.,
      "negNumber": -1.,
      "maxNumber": %raw("Number.MAX_VALUE"),
      "string": "string",
      "longString": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
      "boolean": true,
      "deeplyNested": {
        "foo": "bar",
        "num": 1.,
        "bool": false,
      },
    }),
    (),
  )
})

test("Successfully serializes object from benchmark", t => {
  let struct = S.object(o =>
    {
      "number": o->S.field("number", S.float()),
      "negNumber": o->S.field("negNumber", S.float()),
      "maxNumber": o->S.field("maxNumber", S.float()),
      "string": o->S.field("string", S.string()),
      "longString": o->S.field("longString", S.string()),
      "boolean": o->S.field("boolean", S.bool()),
      "deeplyNested": o->S.field(
        "deeplyNested",
        S.object(
          o =>
            {
              "foo": o->S.field("foo", S.string()),
              "num": o->S.field("num", S.float()),
              "bool": o->S.field("bool", S.bool()),
            },
        ),
      ),
    }
  )

  t->Assert.deepEqual(
    {
      "number": 1.,
      "negNumber": -1.,
      "maxNumber": %raw("Number.MAX_VALUE"),
      "string": "string",
      "longString": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Vivendum intellegat et qui, ei denique consequuntur vix. Semper aeterno percipit ut his, sea ex utinam referrentur repudiandae. No epicuri hendrerit consetetur sit, sit dicta adipiscing ex, in facete detracto deterruisset duo. Quot populo ad qui. Sit fugit nostrum et. Ad per diam dicant interesset, lorem iusto sensibus ut sed. No dicam aperiam vis. Pri posse graeco definitiones cu, id eam populo quaestio adipiscing, usu quod malorum te. Ex nam agam veri, dicunt efficiantur ad qui, ad legere adversarium sit. Commune platonem mel id, brute adipiscing duo an. Vivendum intellegat et qui, ei denique consequuntur vix. Offendit eleifend moderatius ex vix, quem odio mazim et qui, purto expetendis cotidieque quo cu, veri persius vituperata ei nec. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
      "boolean": true,
      "deeplyNested": {
        "foo": "bar",
        "num": 1.,
        "bool": false,
      },
    }->S.serializeWith(struct),
    Ok(
      %raw(`{
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
      }`),
    ),
    (),
  )
})

test("Successfully parses object and serializes it back to the initial data", t => {
  let any = %raw(`{"Name":"Dmitry","Email":"dzakh.dev@gmail.com","Age":21}`)

  let struct = S.object(o =>
    {
      "name": o->S.field("Name", S.string()),
      "email": o->S.field("Email", S.string()),
      "age": o->S.field("Age", S.int()),
    }
  )

  t->Assert.deepEqual(
    any->S.parseWith(struct)->Belt.Result.map(object => object->S.serializeWith(struct)),
    Ok(Ok(any)),
    (),
  )
})

test("Fails to create object struct with unused fields", t => {
  t->Assert.throws(() => {
    S.object(
      o => {
        let _ = o->S.field("unused", S.string())
        {
          "field": o->S.field("field", S.string()),
        }
      },
    )->ignore
  }, ~expectations=ThrowsException.make(
    ~message=String(
      "[rescript-struct] The object defention contains fields that weren\'t registered.",
    ),
    (),
  ), ())
})

test("Fails to create object struct with overused fields", t => {
  t->Assert.throws(() => {
    S.object(
      o => {
        let field = o->S.field("field", S.string())
        {
          "field1": field,
          "field2": field,
        }
      },
    )->ignore
  }, ~expectations=ThrowsException.make(
    ~message=String(
      "[rescript-struct] The object defention has more registered fields than expected.",
    ),
    (),
  ), ())
})
