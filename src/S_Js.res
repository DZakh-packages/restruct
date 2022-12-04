module Stdlib = {
  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolve: (t<'a>, 'a => 'b) => t<'b> = "then"
  }

  module Object = {
    @val
    external extendWith: ('target, 'extend) => 'target = "Object.assign"
  }
}

module Error = {
  type t = exn

  %%raw(`
    class ReScriptStructError extends Error {
      constructor(message) {
        super(message);
        this.name = "ReScriptStructError";
      }
    }
    exports.ReScriptStructError = ReScriptStructError 
  `)

  @new
  external _make: string => t = "ReScriptStructError"

  let make = error => {
    error->S.Error.toString->_make
  }
}

module Result = {
  type t<'value>

  let fromOk = (value: 'value): t<'value> =>
    {
      "success": true,
      "value": value,
    }->Obj.magic

  let fromError = (error: Error.t): t<'value> =>
    {
      "success": false,
      "error": error,
    }->Obj.magic
}

type any
type transformed
type rec struct<'value> = {
  parse: any => Result.t<'value>,
  parseOrThrow: any => 'value,
  parseAsync: any => promise<Result.t<'value>>,
  serialize: 'value => Result.t<S.unknown>,
  serializeOrThrow: 'value => S.unknown,
  transform: (
    ~parser: 'value => transformed,
    ~serializer: transformed => 'value,
  ) => struct<transformed>,
  refine: (~parser: 'value => unit, ~serializer: 'value => unit) => struct<'value>,
  asyncRefine: (~parser: 'value => promise<unit>) => struct<'value>,
  optional: unit => struct<option<'value>>,
  nullable: unit => struct<option<'value>>,
}

let structOperations = %raw("{}")

let castToReScriptStruct: struct<'value> => S.t<'value> = Obj.magic
let castMultipleToReScriptStruct: array<struct<'value>> => array<S.t<'value>> = Obj.magic

@inline
let toJsStruct = struct => {
  let castToJsStruct: S.t<'value> => struct<'value> = Obj.magic
  struct->Stdlib.Object.extendWith(structOperations)->castToJsStruct
}

@inline
let toJsStructFactory = factory => {
  () => factory()->toJsStruct
}

let parse = data => {
  let struct = %raw("this")
  try {
    data->S.parseOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let parseOrThrow = data => {
  let struct = %raw("this")
  try {
    data->S.parseOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let parseAsync = data => {
  let struct = %raw("this")
  data
  ->S.parseAsyncWith(struct)
  ->Stdlib.Promise.thenResolve(result => {
    switch result {
    | Ok(value) => value->Result.fromOk
    | Error(error) => error->Error.make->Result.fromError
    }
  })
}

let serialize = value => {
  let struct = %raw("this")
  try {
    value->S.serializeOrRaiseWith(struct)->Result.fromOk
  } catch {
  | S.Raised(error) => error->Error.make->Result.fromError
  }
}

let serializeOrThrow = value => {
  let struct = %raw("this")
  try {
    value->S.serializeOrRaiseWith(struct)
  } catch {
  | S.Raised(error) => error->Error.make->raise
  }
}

let transform = (~parser, ~serializer) => {
  let struct = %raw("this")
  struct->S.transform(~parser, ~serializer, ())->toJsStruct
}

let refine = (~parser, ~serializer) => {
  let struct = %raw("this")
  struct->S.refine(~parser, ~serializer, ())->toJsStruct
}

let asyncRefine = (~parser) => {
  let struct = %raw("this")
  struct->S.asyncRefine(~parser, ())->toJsStruct
}

let string = S.string->toJsStructFactory
let boolean = S.bool->toJsStructFactory
let integer = S.int->toJsStructFactory
let number = S.float->toJsStructFactory
let never = S.never->toJsStructFactory
let unknown = S.unknown->toJsStructFactory

let optional = struct => S.option(struct->castToReScriptStruct)->toJsStruct
let nullable = struct => S.null(struct->castToReScriptStruct)->toJsStruct
let array = struct => S.array(struct->castToReScriptStruct)->toJsStruct
let record = struct => S.dict(struct->castToReScriptStruct)->toJsStruct
let json = struct => S.json(struct->castToReScriptStruct)->toJsStruct
let union = structs => S.union(structs->castMultipleToReScriptStruct)->toJsStruct
let defaulted = (struct, value) => S.defaulted(struct->castToReScriptStruct, value)->toJsStruct

let literal = {
  let castTaggedToLiteral: S.taggedLiteral => S.literal<'value> = Obj.magic

  (value: 'value): struct<'value> => {
    let taggedLiteral: S.taggedLiteral = {
      if Js.typeof(value) === "string" {
        String(value->Obj.magic)
      } else if Js.typeof(value) === "boolean" {
        Bool(value->Obj.magic)
      } else if Js.typeof(value) === "number" {
        let value = value->Obj.magic
        if value->Js.Float.isNaN {
          Js.Exn.raiseError(`[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead.`)
        } else {
          Float(value)
        }
      } else if value === %raw("null") {
        EmptyNull
      } else if value === %raw("undefined") {
        EmptyOption
      } else {
        Js.Exn.raiseError(`[rescript-struct] The value provided to literal struct factory is not supported.`)
      }
    }
    S.literal(taggedLiteral->castTaggedToLiteral)->toJsStruct
  }
}

let nan = () => S.literal(NaN)->toJsStruct

let custom = (~name, ~parser, ~serializer) => {
  S.custom(~name, ~parser, ~serializer, ())->toJsStruct
}

structOperations->Stdlib.Object.extendWith({
  parse,
  parseOrThrow,
  parseAsync,
  serialize,
  serializeOrThrow,
  transform,
  refine,
  asyncRefine,
  optional: () => {
    %raw("this")->optional
  },
  nullable: () => {
    %raw("this")->nullable
  },
})

module Object = {
  type rec t = {strict: unit => t, strip: unit => t}

  let objectStructOperations = %raw("{}")

  @inline
  let toJsStruct = struct => {
    let castToJsStruct: S.t<'value> => t = Obj.magic
    struct->Stdlib.Object.extendWith(objectStructOperations)->castToJsStruct
  }

  let strict = () => {
    let struct = %raw("this")
    struct->castToReScriptStruct->S.Object.strict->toJsStruct
  }

  let strip = () => {
    let struct = %raw("this")
    struct->castToReScriptStruct->S.Object.strip->toJsStruct
  }

  let factory = definer => {
    S.object(o => {
      let definition = Js.Dict.empty()
      let fieldNames = definer->Js.Dict.keys
      for idx in 0 to fieldNames->Js.Array2.length - 1 {
        let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
        let struct = definer->Js.Dict.unsafeGet(fieldName)->castToReScriptStruct
        definition->Js.Dict.set(fieldName, o->S.field(fieldName, struct))
      }
      definition
    })->toJsStruct
  }

  objectStructOperations->Stdlib.Object.extendWith(structOperations)
  objectStructOperations->Stdlib.Object.extendWith({
    strict,
    strip,
  })
}