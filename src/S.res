type never
type unknown

module Stdlib = {
  module Promise = {
    type t<+'a> = Js.Promise.t<'a>

    @send
    external thenResolve: (t<'a>, 'a => 'b) => t<'b> = "then"

    @send external then: (t<'a>, 'a => t<'b>) => t<'b> = "then"

    @send
    external thenResolveWithCatch: (t<'a>, @uncurry ('a => 'b), @uncurry (exn => 'b)) => t<'b> =
      "then"

    @val @scope("Promise")
    external resolve: 'a => t<'a> = "resolve"

    @send
    external catch: (t<'a>, @uncurry (exn => 'a)) => t<'a> = "catch"

    @scope("Promise") @val
    external all: array<t<'a>> => t<array<'a>> = "all"
  }

  module Url = {
    type t

    @new
    external make: string => t = "URL"

    @inline
    let test = string => {
      try {
        make(string)->ignore
        true
      } catch {
      | _ => false
      }
    }
  }

  module Fn = {
    @inline
    let getArguments = (): array<'a> => {
      %raw(`arguments`)
    }

    @inline
    let call1 = (fn: 'arg1 => 'return, arg1: 'arg1): 'return => {
      Obj.magic(fn)(. arg1)
    }

    @inline
    let castToCurried = (fn: (. 'a) => 'b): ('a => 'b) => fn->Obj.magic
  }

  module Object = {
    @inline
    let test = data => {
      data->Js.typeof === "object" && !Js.Array2.isArray(data) && data !== %raw(`null`)
    }
  }

  module Set = {
    type t<'value>

    @new
    external fromArray: array<'value> => t<'value> = "Set"

    @val("Array.from")
    external toArray: t<'value> => array<'value> = "from"
  }

  module Array = {
    @inline
    let toTuple = array =>
      array->Js.Array2.length <= 1 ? array->Js.Array2.unsafe_get(0)->Obj.magic : array->Obj.magic

    @inline
    let unique = array => array->Set.fromArray->Set.toArray

    @inline
    let set = (array: array<'value>, idx: int, value: 'value) => {
      array->Obj.magic->Js.Dict.set(idx->Obj.magic, value)
    }
  }

  module Result = {
    @inline
    let mapError = (result, fn) =>
      switch result {
      | Ok(_) as ok => ok
      | Error(error) => Error(fn(error))
      }
  }

  module Option = {
    @inline
    let getWithDefault = (option, default) =>
      switch option {
      | Some(value) => value
      | None => default
      }

    @inline
    let flatMap = (option, fn) =>
      switch option {
      | Some(value) => fn(value)
      | None => None
      }
  }

  module Exn = {
    type error

    @new
    external makeError: string => error = "Error"

    let raiseError = (error: error): 'a => error->Obj.magic->raise
  }

  module Int = {
    @inline
    let plus = (int1: int, int2: int): int => {
      (int1->Js.Int.toFloat +. int2->Js.Int.toFloat)->Obj.magic
    }

    @inline
    let test = data => {
      let x = data->Obj.magic
      data->Js.typeof === "number" && x < 2147483648. && x > -2147483649. && mod(x, 1) === 0
    }
  }

  module Dict = {
    @val
    external immutableShallowMerge: (
      @as(json`{}`) _,
      Js.Dict.t<'a>,
      Js.Dict.t<'a>,
    ) => Js.Dict.t<'a> = "Object.assign"
  }
}

module Error = {
  @inline
  let panic = message => Stdlib.Exn.raiseError(Stdlib.Exn.makeError(`[rescript-struct] ${message}`))

  type rec t = {operation: operation, code: code, path: array<string>}
  and code =
    | OperationFailed(string)
    | MissingParser
    | MissingSerializer
    | UnexpectedType({expected: string, received: string})
    | UnexpectedValue({expected: string, received: string})
    | TupleSize({expected: int, received: int})
    | ExcessField(string)
    | InvalidUnion(array<t>)
    | UnexpectedAsync
  and operation =
    | Serializing
    | Parsing

  module Internal = {
    type public = t
    type t = {
      code: code,
      path: array<string>,
    }

    exception Exception(t)

    let raise = code => {
      raise(Exception({code, path: []}))
    }

    let toParseError = (internalError: t): public => {
      {operation: Parsing, code: internalError.code, path: internalError.path}
    }

    let toSerializeError = (internalError: t): public => {
      {operation: Serializing, code: internalError.code, path: internalError.path}
    }

    external fromPublic: public => t = "%identity"

    let prependLocation = (error, location) => {
      {
        ...error,
        path: [location]->Js.Array2.concat(error.path),
      }
    }

    module UnexpectedValue = {
      let stringify = any => {
        switch any->Obj.magic {
        | Some(value) =>
          switch value->Js.Json.stringifyAny {
          | Some(string) => string
          | None => "???"
          }
        | None => "undefined"
        }
      }

      let raise = (~expected, ~received) => {
        raise(
          UnexpectedValue({
            expected: expected->stringify,
            received: received->stringify,
          }),
        )
      }
    }
  }

  module MissingParserAndSerializer = {
    let panic = location => panic(`For a ${location} either a parser, or a serializer is required`)
  }

  module Unreachable = {
    let panic = () => panic("Unreachable")
  }

  module UnionLackingStructs = {
    let panic = () => panic("A Union struct factory require at least two structs")
  }

  let formatPath = path => {
    if path->Js.Array2.length === 0 {
      "root"
    } else {
      path->Js.Array2.map(pathItem => `[${pathItem}]`)->Js.Array2.joinWith("")
    }
  }

  let prependLocation = (error, location) => {
    {
      ...error,
      path: [location]->Js.Array2.concat(error.path),
    }
  }

  let raiseCustom = error => {
    raise(Internal.Exception(error->Internal.fromPublic))
  }

  let raise = message => {
    raise(Internal.Exception({code: OperationFailed(message), path: []}))
  }

  let rec toReason = (~nestedLevel=0, error) => {
    switch error.code {
    | OperationFailed(reason) => reason
    | MissingParser => "Struct parser is missing"
    | MissingSerializer => "Struct serializer is missing"
    | UnexpectedAsync => "Encountered unexpected asynchronous transform or refine. Use parseAsyncWith instead of parseWith"
    | ExcessField(fieldName) =>
      `Encountered disallowed excess key "${fieldName}" on an object. Use Deprecated to ignore a specific field, or S.Object.strip to ignore excess keys completely`
    | UnexpectedType({expected, received})
    | UnexpectedValue({expected, received}) =>
      `Expected ${expected}, received ${received}`
    | TupleSize({expected, received}) =>
      `Expected Tuple with ${expected->Js.Int.toString} items, received ${received->Js.Int.toString}`
    | InvalidUnion(errors) => {
        let lineBreak = `\n${" "->Js.String2.repeat(nestedLevel * 2)}`
        let reasons =
          errors
          ->Js.Array2.map(error => {
            let reason = error->toReason(~nestedLevel=nestedLevel->Stdlib.Int.plus(1))
            let location = switch error.path {
            | [] => ""
            | nonEmptyPath => `Failed at ${formatPath(nonEmptyPath)}. `
            }
            `- ${location}${reason}`
          })
          ->Stdlib.Array.unique
        `Invalid union with following errors${lineBreak}${reasons->Js.Array2.joinWith(lineBreak)}`
      }
    }
  }

  let toString = error => {
    let operation = switch error.operation {
    | Serializing => "serializing"
    | Parsing => "parsing"
    }
    let reason = error->toReason
    let pathText = error.path->formatPath
    `Failed ${operation} at ${pathText}. Reason: ${reason}`
  }
}

exception Raised(Error.t)

type rec literal<'value> =
  | String(string): literal<string>
  | Int(int): literal<int>
  | Float(float): literal<float>
  | Bool(bool): literal<bool>
  | EmptyNull: literal<unit>
  | EmptyOption: literal<unit>
  | NaN: literal<unit>
type taggedLiteral =
  | String(string)
  | Int(int)
  | Float(float)
  | Bool(bool)
  | EmptyNull
  | EmptyOption
  | NaN
type operation =
  | NoOperation
  | SyncOperation((. unknown) => unknown)
  | AsyncOperation((. unknown, . unit) => Js.Promise.t<unknown>)
type rec t<'value> = {
  @as("n")
  name: string,
  @as("t")
  tagged: tagged,
  @as("pf")
  parseTransformationFactory: internalTransformationFactory,
  @as("sf")
  serializeTransformationFactory: internalTransformationFactory,
  @as("s")
  mutable serialize: operation,
  @as("p")
  mutable parse: operation,
  @as("ip")
  isParseInlinable: bool,
  @as("m")
  maybeMetadataDict: option<Js.Dict.t<unknown>>,
}
and tagged =
  | Never
  | Unknown
  | String
  | Int
  | Float
  | Bool
  | Literal(taggedLiteral)
  | Option(t<unknown>)
  | Null(t<unknown>)
  | Array(t<unknown>)
  | Object({fields: Js.Dict.t<t<unknown>>, fieldNames: array<string>})
  | Tuple(array<t<unknown>>)
  | Union(array<t<unknown>>)
  | Dict(t<unknown>)
  | Date
and field<'value> = (string, t<'value>)
and transformation<'input, 'output> =
  | Sync('input => 'output)
  | Async('input => Js.Promise.t<'output>)
and internalTransformationFactoryCtxPhase = NoTransformation | OnlySync | OnlyAsync | SyncAndAsync
and internalTransformationFactoryCtx = {
  @as("p")
  mutable phase: internalTransformationFactoryCtxPhase,
  @as("s")
  mutable syncTransformation: (. unknown) => unknown,
  @as("a")
  mutable asyncTransformation: (. unknown) => Js.Promise.t<unknown>,
}
and internalTransformationFactory = (
  . ~ctx: internalTransformationFactoryCtx,
  ~struct: t<unknown>,
) => unit

type payloadedVariant<'payload> = {_0: 'payload}
let unsafeGetVariantPayload = variant => (variant->Obj.magic)._0

external castAnyToUnknown: 'any => unknown = "%identity"
external castUnknownToAny: unknown => 'any = "%identity"
external castUnknownStructToAnyStruct: t<unknown> => t<'any> = "%identity"
external castAnyStructToUnknownStruct: t<'any> => t<unknown> = "%identity"
external castPublicTransformationFactoryToUncurried: (
  (~struct: t<'value>) => transformation<'input, 'output>,
  . ~struct: t<unknown>,
) => transformation<unknown, unknown> = "%identity"

module TransformationFactory = {
  module Ctx = {
    @inline
    let make = () => {
      {
        phase: NoTransformation,
        syncTransformation: %raw("undefined"),
        asyncTransformation: %raw("undefined"),
      }
    }

    @inline
    let makeSyncTransformation = (fn: 'a => 'b): ((. unknown) => unknown) => fn->Obj.magic

    @inline
    let makeAsyncTransformation = (fn: 'a => Js.Promise.t<'b>): (
      (. unknown) => Js.Promise.t<unknown>
    ) => fn->Obj.magic

    let planSyncTransformation = (ctx, transformation) => {
      let prevSyncTransformation = ctx.syncTransformation
      let prevAsyncTransformation = ctx.asyncTransformation
      let nextSyncTransformation = makeSyncTransformation(transformation)
      switch ctx.phase {
      | NoTransformation => {
          ctx.phase = OnlySync
          ctx.syncTransformation = nextSyncTransformation
        }

      | OnlySync =>
        ctx.syncTransformation = (. input) =>
          nextSyncTransformation(. prevSyncTransformation(. input))

      | OnlyAsync
      | SyncAndAsync =>
        ctx.asyncTransformation = (. input) =>
          prevAsyncTransformation(. input)->Stdlib.Promise.thenResolve(
            nextSyncTransformation->Stdlib.Fn.castToCurried,
          )
      }
    }

    let planAsyncTransformation = (ctx, transformation) => {
      let prevAsyncTransformation = ctx.asyncTransformation
      let nextAsyncTransformation = makeAsyncTransformation(transformation)
      switch ctx.phase {
      | NoTransformation => {
          ctx.phase = OnlyAsync
          ctx.asyncTransformation = nextAsyncTransformation
        }

      | OnlySync => {
          ctx.phase = SyncAndAsync
          ctx.asyncTransformation = nextAsyncTransformation
        }

      | OnlyAsync
      | SyncAndAsync =>
        ctx.asyncTransformation = (. input) =>
          prevAsyncTransformation(. input)->Stdlib.Promise.then(
            nextAsyncTransformation->Stdlib.Fn.castToCurried,
          )
      }
    }

    let planMissingParserTransformation = ctx => {
      ctx->planSyncTransformation(_ => Error.Internal.raise(MissingParser))
    }

    let planMissingSerializerTransformation = ctx => {
      ctx->planSyncTransformation(_ => Error.Internal.raise(MissingSerializer))
    }
  }

  external make: (
    (. ~ctx: internalTransformationFactoryCtx, ~struct: t<'value>) => unit
  ) => internalTransformationFactory = "%identity"

  let empty = make((. ~ctx as _, ~struct as _) => ())

  let compile = (transformationFactory, ~struct) => {
    let ctx = Ctx.make()
    transformationFactory(. ~ctx, ~struct)
    switch ctx.phase {
    | NoTransformation => NoOperation
    | OnlySync => SyncOperation(ctx.syncTransformation)
    | OnlyAsync => AsyncOperation((. input, . ()) => ctx.asyncTransformation(. input))
    | SyncAndAsync =>
      AsyncOperation(
        (. input) => {
          let syncOutput = ctx.syncTransformation(. input)
          (. ()) => ctx.asyncTransformation(. syncOutput)
        },
      )
    }
  }
}

@inline
let classify = struct => struct.tagged

@inline
let name = struct => struct.name

@inline
let isAsyncParse = struct =>
  switch struct.parse {
  | AsyncOperation(_) => true
  | NoOperation
  | SyncOperation(_) => false
  }

let raiseUnexpectedTypeError = (~input: 'any, ~struct: t<'any2>) => {
  Error.Internal.raise(
    UnexpectedType({
      expected: struct.name,
      received: switch input->Js.Types.classify {
      | JSFalse | JSTrue => "Bool"
      | JSString(_) => "String"
      | JSNull => "Null"
      | JSNumber(number) if Js.Float.isNaN(number) => "NaN Literal (NaN)"
      | JSNumber(_) => "Float"
      | JSObject(_) => "Object"
      | JSFunction(_) => "Function"
      | JSUndefined => "Option"
      | JSSymbol(_) => "Symbol"
      | JSBigInt(_) => "BigInt"
      },
    }),
  )
}

let make = (
  ~name,
  ~tagged,
  ~parseTransformationFactory,
  ~serializeTransformationFactory,
  ~isParseInlinable=false,
  ~metadataDict as maybeMetadataDict=?,
  (),
) => {
  let struct = {
    name,
    tagged,
    parseTransformationFactory,
    serializeTransformationFactory,
    serialize: %raw("undefined"),
    parse: %raw("undefined"),
    isParseInlinable,
    maybeMetadataDict,
  }
  struct.parse = struct.parseTransformationFactory->TransformationFactory.compile(~struct)
  struct.serialize = struct.serializeTransformationFactory->TransformationFactory.compile(~struct)
  struct
}

let parseWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoOperation => any->Obj.magic->Ok
    | SyncOperation(fn) => fn(. any->Obj.magic)->Obj.magic->Ok
    | AsyncOperation(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

let parseOrRaiseWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoOperation => any->Obj.magic
    | SyncOperation(fn) => fn(. any->Obj.magic)->Obj.magic
    | AsyncOperation(_) => Error.Internal.raise(UnexpectedAsync)
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toParseError))
  }
}

let parseAsyncWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoOperation => any->Obj.magic->Ok->Stdlib.Promise.resolve
    | SyncOperation(fn) => fn(. any->Obj.magic)->Ok->Obj.magic->Stdlib.Promise.resolve
    | AsyncOperation(fn) =>
      fn(. any->Obj.magic)(.)
      ->Stdlib.Promise.thenResolve(value => Ok(value->Obj.magic))
      ->Stdlib.Promise.catch(exn => {
        switch exn {
        | Error.Internal.Exception(internalError) =>
          internalError->Error.Internal.toParseError->Error
        | _ => raise(exn)
        }
      })
    }
  } catch {
  | Error.Internal.Exception(internalError) =>
    internalError->Error.Internal.toParseError->Error->Stdlib.Promise.resolve
  }
}

let parseAsyncInStepsWith = (any, struct) => {
  try {
    switch struct.parse {
    | NoOperation => () => any->Obj.magic->Ok->Stdlib.Promise.resolve
    | SyncOperation(fn) => {
        let syncValue = fn(. any->castAnyToUnknown)->castUnknownToAny
        () => syncValue->Ok->Stdlib.Promise.resolve
      }

    | AsyncOperation(fn) => {
        let asyncFn = fn(. any->castAnyToUnknown)
        () =>
          asyncFn(.)
          ->Stdlib.Promise.thenResolve(value => Ok(value->Obj.magic))
          ->Stdlib.Promise.catch(exn => {
            switch exn {
            | Error.Internal.Exception(internalError) =>
              internalError->Error.Internal.toParseError->Error
            | _ => raise(exn)
            }
          })
      }
    }->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toParseError->Error
  }
}

@inline
let serializeInner: (~struct: t<'value>, ~value: 'value) => unknown = (~struct, ~value) => {
  switch struct.serialize {
  | NoOperation => value->castAnyToUnknown
  | SyncOperation(fn) => fn(. value->castAnyToUnknown)
  | AsyncOperation(_) => Error.Unreachable.panic()
  }
}

let serializeWith = (value, struct) => {
  try {
    serializeInner(~struct, ~value)->Ok
  } catch {
  | Error.Internal.Exception(internalError) => internalError->Error.Internal.toSerializeError->Error
  }
}

let serializeOrRaiseWith = (value, struct) => {
  try {
    serializeInner(~struct, ~value)
  } catch {
  | Error.Internal.Exception(internalError) =>
    raise(Raised(internalError->Error.Internal.toSerializeError))
  }
}

module Metadata = {
  external castDictOfAnyToUnknown: Js.Dict.t<'any> => Js.Dict.t<unknown> = "%identity"

  module Id: {
    type t<'metadata>
    let make: (~namespace: string, ~name: string) => t<'metadata>
    external toKey: t<'metadata> => string = "%identity"
  } = {
    type t<'metadata> = string

    let make = (~namespace, ~name) => {
      `${namespace}:${name}`
    }

    external toKey: t<'metadata> => string = "%identity"
  }

  module Change = {
    @inline
    let make = (~id: Id.t<'metadata>, ~metadata: 'metadata) => {
      let metadataChange = Js.Dict.empty()
      metadataChange->Js.Dict.set(id->Id.toKey, metadata)
      metadataChange->castDictOfAnyToUnknown
    }
  }

  let get = (struct, ~id: Id.t<'metadata>): option<'metadata> => {
    struct.maybeMetadataDict->Stdlib.Option.flatMap(metadataDict => {
      metadataDict->Js.Dict.get(id->Id.toKey)->Obj.magic
    })
  }

  let set = (struct, ~id: Id.t<'metadata>, ~metadata: 'metadata) => {
    make(
      ~name=struct.name,
      ~parseTransformationFactory=struct.parseTransformationFactory,
      ~serializeTransformationFactory=struct.serializeTransformationFactory,
      ~tagged=struct.tagged,
      ~metadataDict=Stdlib.Dict.immutableShallowMerge(
        struct.maybeMetadataDict->Obj.magic,
        Change.make(~id, ~metadata),
      ),
      (),
    )
  }
}

let refine: (
  t<'value>,
  ~parser: 'value => unit=?,
  ~serializer: 'value => unit=?,
  unit,
) => t<'value> = (
  struct,
  ~parser as maybeRefineParser=?,
  ~serializer as maybeRefineSerializer=?,
  (),
) => {
  if maybeRefineParser === None && maybeRefineSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Refine`)
  }

  let nextParseTransformationFactory = switch maybeRefineParser {
  | Some(refineParser) =>
    TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
        let () = refineParser->Stdlib.Fn.call1(input)
        input
      })
    })
  | None => struct.parseTransformationFactory
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=nextParseTransformationFactory,
    ~serializeTransformationFactory=switch maybeRefineSerializer {
    | Some(refineSerializer) =>
      TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          let () = refineSerializer->Stdlib.Fn.call1(input)
          input
        })
        struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
      })
    | None => struct.serializeTransformationFactory
    },
    ~metadataDict=?struct.maybeMetadataDict,
    ~isParseInlinable=nextParseTransformationFactory === struct.parseTransformationFactory
      ? struct.isParseInlinable
      : false,
    (),
  )
}

let asyncRefine = (struct, ~parser, ()) => {
  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
        parser
        ->Stdlib.Fn.call1(input)
        ->Stdlib.Promise.thenResolve(
          () => {
            input
          },
        )
      })
    }),
    ~serializeTransformationFactory=struct.serializeTransformationFactory,
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let transform: (
  t<'value>,
  ~parser: 'value => 'transformed=?,
  ~serializer: 'transformed => 'value=?,
  unit,
) => t<'transformed> = (
  struct,
  ~parser as maybeTransformParser=?,
  ~serializer as maybeTransformSerializer=?,
  (),
) => {
  if maybeTransformParser === None && maybeTransformSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      switch maybeTransformParser {
      | Some(transformParser) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(transformParser)
      | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
      }
    }),
    ~serializeTransformationFactory=TransformationFactory.make((
      . ~ctx,
      ~struct as compilingStruct,
    ) => {
      switch maybeTransformSerializer {
      | Some(transformSerializer) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(transformSerializer)
      | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
      }
      struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
    }),
    ~metadataDict=?struct.maybeMetadataDict,
    ~isParseInlinable=false,
    (),
  )
}

let advancedTransform: (
  t<'value>,
  ~parser: (~struct: t<'value>) => transformation<'value, 'transformed>=?,
  ~serializer: (~struct: t<'value>) => transformation<'transformed, 'value>=?,
  unit,
) => t<'transformed> = (
  struct,
  ~parser as maybeTransformParser=?,
  ~serializer as maybeTransformSerializer=?,
  (),
) => {
  if maybeTransformParser === None && maybeTransformSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Transform`)
  }

  make(
    ~name=struct.name,
    ~tagged=struct.tagged,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as compilingStruct) => {
      struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      switch maybeTransformParser {
      | Some(transformParser) =>
        switch (transformParser->castPublicTransformationFactoryToUncurried)(.
          ~struct=compilingStruct->castUnknownStructToAnyStruct,
        ) {
        | Sync(syncTransformation) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
        | Async(asyncTransformation) =>
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
        }
      | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
      }
    }),
    ~serializeTransformationFactory=TransformationFactory.make((
      . ~ctx,
      ~struct as compilingStruct,
    ) => {
      switch maybeTransformSerializer {
      | Some(transformSerializer) =>
        switch (transformSerializer->castPublicTransformationFactoryToUncurried)(.
          ~struct=compilingStruct->castUnknownStructToAnyStruct,
        ) {
        | Sync(syncTransformation) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
        | Async(asyncTransformation) =>
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
        }
      | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
      }
      struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
    }),
    ~metadataDict=?struct.maybeMetadataDict,
    (),
  )
}

let rec advancedPreprocess = (
  struct,
  ~parser as maybePreprocessParser=?,
  ~serializer as maybePreprocessSerializer=?,
  (),
) => {
  if maybePreprocessParser === None && maybePreprocessSerializer === None {
    Error.MissingParserAndSerializer.panic(`struct factory Preprocess`)
  }

  switch struct->classify {
  | Union(unionStructs) =>
    make(
      ~name=struct.name,
      ~tagged=Union(
        unionStructs->Js.Array2.map(unionStruct =>
          unionStruct
          ->castUnknownStructToAnyStruct
          ->advancedPreprocess(
            ~parser=?maybePreprocessParser,
            ~serializer=?maybePreprocessSerializer,
            (),
          )
          ->castAnyStructToUnknownStruct
        ),
      ),
      ~parseTransformationFactory=struct.parseTransformationFactory,
      ~serializeTransformationFactory=struct.serializeTransformationFactory,
      ~metadataDict=?struct.maybeMetadataDict,
      (),
    )
  | _ =>
    make(
      ~name=struct.name,
      ~tagged=struct.tagged,
      ~parseTransformationFactory=TransformationFactory.make((
        . ~ctx,
        ~struct as compilingStruct,
      ) => {
        switch maybePreprocessParser {
        | Some(preprocessParser) =>
          switch (preprocessParser->castPublicTransformationFactoryToUncurried)(.
            ~struct=compilingStruct->castUnknownStructToAnyStruct,
          ) {
          | Sync(syncTransformation) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
          | Async(asyncTransformation) =>
            ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
          }
        | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
        }
        struct.parseTransformationFactory(. ~ctx, ~struct=compilingStruct)
      }),
      ~serializeTransformationFactory=TransformationFactory.make((
        . ~ctx,
        ~struct as compilingStruct,
      ) => {
        struct.serializeTransformationFactory(. ~ctx, ~struct=compilingStruct)
        switch maybePreprocessSerializer {
        | Some(preprocessSerializer) =>
          switch (preprocessSerializer->castPublicTransformationFactoryToUncurried)(.
            ~struct=compilingStruct->castUnknownStructToAnyStruct,
          ) {
          | Sync(syncTransformation) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
          | Async(asyncTransformation) =>
            ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncTransformation)
          }
        | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
        }
      }),
      ~metadataDict=?struct.maybeMetadataDict,
      (),
    )
  }
}

let custom = (
  ~name,
  ~parser as maybeCustomParser=?,
  ~serializer as maybeCustomSerializer=?,
  (),
) => {
  if maybeCustomParser === None && maybeCustomSerializer === None {
    Error.MissingParserAndSerializer.panic(`Custom struct factory`)
  }

  make(
    ~name,
    ~tagged=Unknown,
    ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
      switch maybeCustomParser {
      | Some(customParser) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(customParser->Obj.magic)
      | None => ctx->TransformationFactory.Ctx.planMissingParserTransformation
      }
    }),
    ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
      switch maybeCustomSerializer {
      | Some(customSerializer) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(customSerializer->Obj.magic)
      | None => ctx->TransformationFactory.Ctx.planMissingSerializerTransformation
      }
    }),
    (),
  )
}

module Literal = {
  external castToTaggedLiteral: literal<'a> => taggedLiteral = "%identity"

  module Variant = {
    let factory:
      type literalValue variant. (literal<literalValue>, variant) => t<variant> =
      (innerLiteral, variant) => {
        let tagged = Literal(innerLiteral->castToTaggedLiteral)

        let makeParseTransformationFactory = (~literalValue, ~test) => {
          TransformationFactory.make((. ~ctx, ~struct) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
              if test->Stdlib.Fn.call1(input) {
                if literalValue->castAnyToUnknown === input {
                  variant
                } else {
                  Error.Internal.UnexpectedValue.raise(~expected=literalValue, ~received=input)
                }
              } else {
                raiseUnexpectedTypeError(~input, ~struct)
              }
            })
          )
        }

        let makeSerializeTransformationFactory = output => {
          TransformationFactory.make((. ~ctx, ~struct as _) =>
            ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
              if input === variant {
                output
              } else {
                Error.Internal.UnexpectedValue.raise(~expected=variant, ~received=input)
              }
            })
          )
        }

        switch innerLiteral {
        | EmptyNull =>
          make(
            ~name="EmptyNull Literal (null)",
            ~tagged,
            ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
              ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
                if input === Js.Null.empty {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(Js.Null.empty),
            (),
          )
        | EmptyOption =>
          make(
            ~name="EmptyOption Literal (undefined)",
            ~tagged,
            ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
              ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
                if input === Js.Undefined.empty {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(Js.Undefined.empty),
            (),
          )
        | NaN =>
          make(
            ~name="NaN Literal (NaN)",
            ~tagged,
            ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
              ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
                if Js.Float.isNaN(input) {
                  variant
                } else {
                  raiseUnexpectedTypeError(~input, ~struct)
                }
              })
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(Js.Float._NaN),
            (),
          )
        | Bool(bool) =>
          make(
            ~name=j`Bool Literal ($bool)`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=bool,
              ~test=input => input->Js.typeof === "boolean",
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(bool),
            (),
          )
        | String(string) =>
          make(
            ~name=`String Literal ("${string}")`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=string,
              ~test=input => input->Js.typeof === "string",
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(string),
            (),
          )
        | Float(float) =>
          make(
            ~name=`Float Literal (${float->Js.Float.toString})`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=float,
              ~test=input => input->Js.typeof === "number",
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(float),
            (),
          )
        | Int(int) =>
          make(
            ~name=`Int Literal (${int->Js.Int.toString})`,
            ~tagged,
            ~parseTransformationFactory=makeParseTransformationFactory(
              ~literalValue=int,
              ~test=input => input->Stdlib.Int.test,
            ),
            ~serializeTransformationFactory=makeSerializeTransformationFactory(int),
            (),
          )
        }
      }
  }

  let factory:
    type value. literal<value> => t<value> =
    innerLiteral => {
      switch innerLiteral {
      | EmptyNull => Variant.factory(innerLiteral, ())
      | EmptyOption => Variant.factory(innerLiteral, ())
      | NaN => Variant.factory(innerLiteral, ())
      | Bool(value) => Variant.factory(innerLiteral, value)
      | String(value) => Variant.factory(innerLiteral, value)
      | Float(value) => Variant.factory(innerLiteral, value)
      | Int(value) => Variant.factory(innerLiteral, value)
      }
    }
}

module Object = {
  module UnknownKeys = {
    type tagged =
      | Strict
      | Strip

    let metadataId: Metadata.Id.t<tagged> = Metadata.Id.make(
      ~namespace="rescript-struct",
      ~name="Object_UnknownKeys",
    )

    let classify = struct =>
      struct->Metadata.get(~id=metadataId)->Stdlib.Option.getWithDefault(Strip)
  }

  let getMaybeExcessKey: (
    . unknown,
    Js.Dict.t<t<unknown>>,
  ) => option<string> = %raw(`function(object, innerStructsDict) {
    for (var key in object) {
      if (!Object.prototype.hasOwnProperty.call(innerStructsDict, key)) {
        return key
      }
    }
  }`)

  let factory = (
    () => {
      let fieldsArray = Stdlib.Fn.getArguments()
      let fields = fieldsArray->Js.Dict.fromArray
      let fieldNames = fields->Js.Dict.keys

      make(
        ~name="Object",
        ~tagged=Object({fields, fieldNames}),
        ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
          let unknownKeys = struct->UnknownKeys.classify

          let noopOps = []
          let syncOps = []
          let asyncOps = []
          for idx in 0 to fieldNames->Js.Array2.length - 1 {
            let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
            let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
            switch fieldStruct.parse {
            | NoOperation => noopOps->Js.Array2.push((idx, fieldName))->ignore
            | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fieldName, fn))->ignore
            | AsyncOperation(fn) => {
                syncOps->Js.Array2.push((idx, fieldName, fn->Obj.magic))->ignore
                asyncOps->Js.Array2.push((idx, fieldName))->ignore
              }
            }
          }
          let withAsyncOps = asyncOps->Js.Array2.length > 0

          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            if input->Stdlib.Object.test === false {
              raiseUnexpectedTypeError(~input, ~struct)
            }

            let newArray = []

            for idx in 0 to syncOps->Js.Array2.length - 1 {
              let (originalIdx, fieldName, fn) = syncOps->Js.Array2.unsafe_get(idx)
              let fieldData = input->Js.Dict.unsafeGet(fieldName)
              try {
                let value = fn(. fieldData)
                newArray->Stdlib.Array.set(originalIdx, value)
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(fieldName),
                  ),
                )
              }
            }

            for idx in 0 to noopOps->Js.Array2.length - 1 {
              let (originalIdx, fieldName) = noopOps->Js.Array2.unsafe_get(idx)
              let fieldData = input->Js.Dict.unsafeGet(fieldName)
              newArray->Stdlib.Array.set(originalIdx, fieldData)
            }

            if unknownKeys === UnknownKeys.Strict {
              switch getMaybeExcessKey(. input->castAnyToUnknown, fields) {
              | Some(excessKey) => Error.Internal.raise(ExcessField(excessKey))
              | None => ()
              }
            }

            withAsyncOps ? newArray->castAnyToUnknown : newArray->Stdlib.Array.toTuple
          })

          if withAsyncOps {
            ctx->TransformationFactory.Ctx.planAsyncTransformation(tempArray => {
              asyncOps
              ->Js.Array2.map(
                ((originalIdx, fieldName)) => {
                  (
                    tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Stdlib.Promise.catch(
                    exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(
                          internalError->Error.Internal.prependLocation(fieldName),
                        )
                      | _ => exn
                      }->raise
                    },
                  )
                },
              )
              ->Stdlib.Promise.all
              ->Stdlib.Promise.thenResolve(
                asyncFieldValues => {
                  asyncFieldValues->Js.Array2.forEachi(
                    (fieldValue, idx) => {
                      let (originalIdx, _) = asyncOps->Js.Array2.unsafe_get(idx)
                      tempArray->castUnknownToAny->Stdlib.Array.set(originalIdx, fieldValue)
                    },
                  )
                  tempArray
                },
              )
            })
          }
        }),
        ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let unknown = Js.Dict.empty()
            let fieldValues =
              fieldNames->Js.Array2.length <= 1 ? [input]->Obj.magic : input->Obj.magic
            for idx in 0 to fieldNames->Js.Array2.length - 1 {
              let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
              let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
              let fieldValue = fieldValues->Js.Array2.unsafe_get(idx)
              switch fieldStruct.serialize {
              | NoOperation => unknown->Js.Dict.set(fieldName, fieldValue)
              | SyncOperation(fn) =>
                try {
                  let fieldData = fn(. fieldValue)
                  unknown->Js.Dict.set(fieldName, fieldData)
                } catch {
                | Error.Internal.Exception(internalError) =>
                  raise(
                    Error.Internal.Exception(
                      internalError->Error.Internal.prependLocation(fieldName),
                    ),
                  )
                }
              | AsyncOperation(_) => Error.Unreachable.panic()
              }
            }
            unknown
          })
        ),
        (),
      )
    }
  )->Obj.magic

  let strip = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, ~metadata=UnknownKeys.Strip)
  }

  let strict = struct => {
    struct->Metadata.set(~id=UnknownKeys.metadataId, ~metadata=UnknownKeys.Strict)
  }
}

module Object2 = {
  module Inline = {
    module Constant = {
      let errorVar = "$_e"
    }

    module Fn = {
      @inline
      let make = (~arguments, ~content) => {
        `function(${arguments}){${content}}`
      }
    }

    module If = {
      @inline
      let make = (~condition, ~content) => {
        `if(${condition}){${content}}`
      }
    }

    module TryCatch = {
      @inline
      let make = (~tryContent, ~catchContent) => {
        `try{${tryContent}}catch(${Constant.errorVar}){${catchContent}}`
      }
    }
  }

  module FieldPlaceholder = {
    type t

    let value: t = %raw(`Symbol("rescript-struct:Object.FieldPlaceholder")`)

    let castToAny: t => 'a = Obj.magic
  }

  module BuilderCtx = {
    type struct = t<unknown>
    type t = {originalFieldNames: array<string>, originalFields: Js.Dict.t<struct>}

    @inline
    let make = () => {
      originalFieldNames: [],
      originalFields: Js.Dict.empty(),
    }

    @inline
    let addFieldUsage = (builderCtx, ~struct, ~originalFieldName) => {
      builderCtx.originalFieldNames->Js.Array2.push(originalFieldName)->ignore
      builderCtx.originalFields->Js.Dict.set(originalFieldName, struct)
    }
  }

  module Metadata = {
    type struct = t<unknown>

    type t =
      | NoFields({
          transformed: unknown,
          originalFields: Js.Dict.t<struct>,
          originalFieldNames: array<string>,
        })
      | WithFields({
          builderFieldNamesByOriginal: Js.Dict.t<string>,
          originalFieldNamesByBuilder: Js.Dict.t<string>,
          originalFields: Js.Dict.t<struct>,
          originalFieldNames: array<string>,
        })

    @inline
    let fromBuilderResult = (builderResult, ~originalFieldNames, ~originalFields) => {
      switch originalFieldNames {
      | [] => NoFields({transformed: builderResult, originalFieldNames, originalFields})
      | _ => {
          if builderResult->Stdlib.Object.test->not {
            Error.panic("The object builder result should be an object.")
          }
          let builderResult: Js.Dict.t<unknown> = builderResult->Obj.magic

          let builderFieldNames = builderResult->Js.Dict.keys

          {
            let builderFieldNamesNumber = builderFieldNames->Js.Array2.length
            let originalFieldNamesNumber = originalFieldNames->Js.Array2.length
            if builderFieldNamesNumber > originalFieldNamesNumber {
              Error.panic("The object builder result missing field defenitions.")
            }
            if builderFieldNamesNumber < originalFieldNamesNumber {
              Error.panic("The object builder result has unused field defenitions.")
            }
          }

          let builderFieldNamesByOriginal = Js.Dict.empty()
          let originalFieldNamesByBuilder = Js.Dict.empty()

          for idx in 0 to builderFieldNames->Js.Array2.length - 1 {
            let builderFieldName = builderFieldNames->Js.Array2.unsafe_get(idx)
            let originalFieldName = originalFieldNames->Js.Array2.unsafe_get(idx)
            originalFieldNamesByBuilder->Js.Dict.set(builderFieldName, originalFieldName)
            builderFieldNamesByOriginal->Js.Dict.set(originalFieldName, builderFieldName)
          }

          WithFields({
            builderFieldNamesByOriginal,
            originalFieldNamesByBuilder,
            originalFieldNames,
            originalFields,
          })
        }
      }
    }
  }

  let factory = builder => {
    let metadata = {
      let builderCtx = BuilderCtx.make()
      builder
      ->Stdlib.Fn.call1(builderCtx)
      ->castAnyToUnknown
      ->Metadata.fromBuilderResult(
        ~originalFieldNames=builderCtx.originalFieldNames,
        ~originalFields=builderCtx.originalFields,
      )
    }
    switch metadata {
    | NoFields({transformed, originalFieldNames, originalFields}) =>
      make(
        ~name="Object",
        ~tagged=Object({fields: originalFields, fieldNames: originalFieldNames}),
        ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            if input->Stdlib.Object.test === false {
              raiseUnexpectedTypeError(~input, ~struct)
            }
            transformed
          })
        }),
        ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(_ => Js.Dict.empty())
        }),
        (),
      )
    | WithFields({
        builderFieldNamesByOriginal,
        // originalFieldNamesByBuilder,
        originalFieldNames,
        originalFields,
      }) =>
      make(
        ~name="Object",
        ~tagged=Object({fields: originalFields, fieldNames: originalFieldNames}),
        ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
          let withUnknownKeysRefinement =
            struct->Object.UnknownKeys.classify === Object.UnknownKeys.Strict

          let parseFnsByOriginalFieldName = Js.Dict.empty()
          // FIXME:
          let asyncOps = []

          let inlinedParseFunction = {
            let originalObjectVar = "$_oo"
            let newObjectVar = "$_no"
            let fieldNameVar = "$_fn"
            let ctxVar = "$_c"

            let refinement = Inline.If.make(
              // TODO: Measure the fastest condition
              ~condition=`(typeof ${originalObjectVar} === "object" && !Array.isArray(${originalObjectVar}) && ${originalObjectVar} !== null) === false`,
              ~content=`${ctxVar}.raiseUnexpectedTypeError(${originalObjectVar},${ctxVar}.struct)`,
            )

            let createNewObject = `var ${newObjectVar}={}`

            let newObjectConstruction = {
              let tryContent = {
                let stringRef = ref("")
                for idx in 0 to originalFieldNames->Js.Array2.length - 1 {
                  let originalFieldName = originalFieldNames->Js.Array2.unsafe_get(idx)
                  let fieldName = builderFieldNamesByOriginal->Js.Dict.unsafeGet(originalFieldName)
                  let fieldStruct = originalFields->Js.Dict.unsafeGet(originalFieldName)
                  let maybeParseFn = switch fieldStruct.parse {
                  | NoOperation => None
                  | SyncOperation(fn) => Some(fn)
                  | AsyncOperation(fn) => {
                      asyncOps
                      ->Js.Array2.push((originalFieldName, "TODO: original field name"))
                      ->ignore
                      Some(fn->Obj.magic)
                    }
                  }
                  switch (maybeParseFn, fieldStruct.isParseInlinable) {
                  | (None, _) =>
                    stringRef.contents =
                      stringRef.contents ++
                      `${newObjectVar}.${fieldName}:${originalObjectVar}.${originalFieldName};`
                  | (Some(fn), true) => {
                      parseFnsByOriginalFieldName->Js.Dict.set(originalFieldName, fn)

                      let inlinedFn =
                        fn
                        ->Obj.magic
                        ->Js.Int.toString
                        ->Js.String2.replace("function (input) ", "")
                        ->Js.String2.replace(
                          "raiseUnexpectedTypeError(input, struct)",
                          `${fieldNameVar}="${originalFieldName}",${ctxVar}.raiseUnexpectedTypeError(input,${ctxVar}.fields.${originalFieldName})`,
                        )
                        ->Js.String2.replaceByRe(%re(`/return/g`), "")

                      stringRef.contents =
                        stringRef.contents ++
                        `var input=${originalObjectVar}.${originalFieldName};${inlinedFn};${newObjectVar}.${fieldName}=input;`
                    }

                  | (Some(fn), false) => {
                      parseFnsByOriginalFieldName->Js.Dict.set(originalFieldName, fn)

                      stringRef.contents =
                        stringRef.contents ++
                        `${fieldNameVar}="${originalFieldName}",${newObjectVar}.${fieldName}=${ctxVar}.fns.${originalFieldName}(${originalObjectVar}.${originalFieldName});`
                    }
                  }
                }
                stringRef.contents
              }

              `var ${fieldNameVar};` ++
              Inline.TryCatch.make(
                ~tryContent,
                ~catchContent=`${ctxVar}.catchFieldError(${Inline.Constant.errorVar},${fieldNameVar})`,
              )
            }

            let unknownKeysRefinement = {
              let stringRef = ref(`for(var key in ${originalObjectVar}){switch(key){`)
              for idx in 0 to originalFieldNames->Js.Array2.length - 1 {
                let originalFieldName = originalFieldNames->Js.Array2.unsafe_get(idx)
                stringRef.contents = stringRef.contents ++ `case"${originalFieldName}":continue;`
              }
              stringRef.contents ++ `default:${ctxVar}.raiseOnExcessField(key);}}`
            }

            Inline.Fn.make(
              ~arguments=originalObjectVar,
              ~content=`${refinement};${createNewObject};${newObjectConstruction};${withUnknownKeysRefinement
                  ? unknownKeysRefinement
                  : ""}return ${newObjectVar}`,
            )
          }

          let syncTransformation = %raw(`new Function('$_c','return '+inlinedParseFunction)`)(. {
            "struct": struct,
            "fns": parseFnsByOriginalFieldName,
            "fields": originalFields,
            "raiseUnexpectedTypeError": raiseUnexpectedTypeError,
            "raiseOnExcessField": exccessFieldName =>
              Error.Internal.raise(ExcessField(exccessFieldName)),
            "catchFieldError": (~exn, ~fieldName) => {
              switch exn {
              | Error.Internal.Exception(internalError) =>
                Error.Internal.Exception(internalError->Error.Internal.prependLocation(fieldName))
              | _ => exn
              }->raise
            },
            // FIXME: Find some better way to do it
            // Use the inlinedParseFunction two times, so rescript compiler doesn't inline the variable
            "a": inlinedParseFunction,
            "b": inlinedParseFunction,
          })

          ctx->TransformationFactory.Ctx.planSyncTransformation(syncTransformation)
        }),
        ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
          let fieldNames = %raw("undefined")
          let fields = %raw("undefined")

          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let unknown = Js.Dict.empty()
            let fieldValues =
              fieldNames->Js.Array2.length <= 1 ? [input]->Obj.magic : input->Obj.magic
            for idx in 0 to fieldNames->Js.Array2.length - 1 {
              let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
              let fieldStruct = fields->Js.Dict.unsafeGet(fieldName)
              let fieldValue = fieldValues->Js.Array2.unsafe_get(idx)
              switch fieldStruct.serialize {
              | NoOperation => unknown->Js.Dict.set(fieldName, fieldValue)
              | SyncOperation(fn) =>
                try {
                  let fieldData = fn(. fieldValue)
                  unknown->Js.Dict.set(fieldName, fieldData)
                } catch {
                | Error.Internal.Exception(internalError) =>
                  raise(
                    Error.Internal.Exception(
                      internalError->Error.Internal.prependLocation(fieldName),
                    ),
                  )
                }
              | AsyncOperation(_) => Error.Unreachable.panic()
              }
            }
            unknown
          })
        }),
        (),
      )
    }
  }

  let field = (builderCtx, originalFieldName, struct) => {
    let struct = struct->castAnyStructToUnknownStruct
    builderCtx->BuilderCtx.addFieldUsage(~struct, ~originalFieldName)
    FieldPlaceholder.value->FieldPlaceholder.castToAny
  }

  type builderCtx = BuilderCtx.t
}

module Never = {
  let factory = () => {
    let transformationFactory = TransformationFactory.make((. ~ctx, ~struct) =>
      ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
        raiseUnexpectedTypeError(~input, ~struct)
      })
    )

    make(
      ~name=`Never`,
      ~tagged=Never,
      ~parseTransformationFactory=transformationFactory,
      ~serializeTransformationFactory=transformationFactory,
      (),
    )
  }
}

module Unknown = {
  let factory = () => {
    make(
      ~name=`Unknown`,
      ~tagged=Unknown,
      ~parseTransformationFactory=TransformationFactory.empty,
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }
}

module String = {
  let cuidRegex = %re(`/^c[^\s-]{8,}$/i`)
  let uuidRegex = %re(`/^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i`)
  let emailRegex = %re(`/^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i`)

  let factory = () => {
    make(
      ~name="String",
      ~tagged=String,
      ~isParseInlinable=true,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Js.typeof === "string" {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length < length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `String must be ${length->Js.Int.toString} or more characters long`,
          ),
        )
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length > length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `String must be ${length->Js.Int.toString} or fewer characters long`,
          ),
        )
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value =>
      if value->Js.String2.length !== length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `String must be exactly ${length->Js.Int.toString} characters long`,
          ),
        )
      }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let email = (struct, ~message=`Invalid email address`, ()) => {
    let refiner = value => {
      if !(emailRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let uuid = (struct, ~message=`Invalid UUID`, ()) => {
    let refiner = value => {
      if !(uuidRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let cuid = (struct, ~message=`Invalid CUID`, ()) => {
    let refiner = value => {
      if !(cuidRegex->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let url = (struct, ~message=`Invalid url`, ()) => {
    let refiner = value => {
      if !(value->Stdlib.Url.test) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let pattern = (struct, ~message=`Invalid`, re) => {
    let refiner = value => {
      re->Js.Re.setLastIndex(0)
      if !(re->Js.Re.test_(value)) {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let trimmed = (struct, ()) => {
    let transformer = Js.String2.trim
    struct->transform(~parser=transformer, ~serializer=transformer, ())
  }
}

module Json = {
  let factory = innerStruct => {
    make(
      ~name=`Json`,
      ~tagged=String,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
        let process = switch innerStruct.parse {
        | NoOperation => Obj.magic
        | SyncOperation(fn) => fn->Obj.magic
        | AsyncOperation(fn) => fn->Obj.magic
        }
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Js.typeof === "string" {
            try input->Js.Json.parseExn catch {
            | Js.Exn.Error(obj) =>
              Error.raise(obj->Js.Exn.message->Stdlib.Option.getWithDefault("Failed to parse JSON"))
            }->Stdlib.Fn.call1(process, _)
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
        switch innerStruct.parse {
        | AsyncOperation(_) =>
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncFn => {
            asyncFn(.)
          })
        | _ => ()
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          serializeInner(~struct=innerStruct, ~value=input)->Obj.magic->Js.Json.stringify
        })
      }),
      (),
    )
  }
}

module Bool = {
  let factory = () => {
    make(
      ~name="Bool",
      ~tagged=Bool,
      ~isParseInlinable=true,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Js.typeof === "boolean" {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }
}

module Int = {
  let factory = () => {
    make(
      ~name="Int",
      ~tagged=Int,
      ~isParseInlinable=true,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if Stdlib.Int.test(input) {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value => {
      if value < thanValue {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Number must be greater than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, thanValue) => {
    let refiner = value => {
      if value > thanValue {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Number must be lower than or equal to ${thanValue->Js.Int.toString}`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let port = (struct, ~message="Invalid port", ()) => {
    let refiner = value => {
      if value < 1 || value > 65535 {
        Error.raise(message)
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }
}

module Float = {
  let factory = () => {
    make(
      ~name="Float",
      ~tagged=Float,
      ~isParseInlinable=true,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          switch input->Js.typeof === "number" {
          | true =>
            if Js.Float.isNaN(input) {
              raiseUnexpectedTypeError(~input, ~struct)
            } else {
              input
            }
          | false => raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }

  let min = Int.min->Obj.magic
  let max = Int.max->Obj.magic
}

module Date = {
  let factory = () => {
    make(
      ~name="Date",
      ~tagged=Date,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if %raw(`input instanceof Date`) && input->Js.Date.getTime->Js.Float.isNaN->not {
            input
          } else {
            raiseUnexpectedTypeError(~input, ~struct)
          }
        })
      ),
      ~serializeTransformationFactory=TransformationFactory.empty,
      (),
    )
  }
}

module Null = {
  let factory = innerStruct => {
    make(
      ~name=`Null`,
      ~tagged=Null(innerStruct->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input->Js.Null.toOption {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }
          })
        }
        switch innerStruct.parse {
        | NoOperation => ctx->TransformationFactory.Ctx.planSyncTransformation(Js.Null.toOption)
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) => {
            planSyncTransformation(fn)
            ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
              switch input {
              | Some(asyncFn) => asyncFn(.)->Stdlib.Promise.thenResolve(value => Some(value))
              | None => None->Stdlib.Promise.resolve
              }
            })
          }
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          switch input {
          | Some(value) => serializeInner(~struct=innerStruct, ~value)
          | None => Js.Null.empty->castAnyToUnknown
          }
        })
      ),
      (),
    )
  }
}

module Option = {
  let factory = innerStruct => {
    make(
      ~name=`Option`,
      ~tagged=Option(innerStruct->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch input {
            | Some(innerData) => Some(fn(. innerData))
            | None => None
            }
          })
        }
        switch innerStruct.parse {
        | NoOperation => ()
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) => {
            planSyncTransformation(fn)
            ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
              switch input {
              | Some(asyncFn) => asyncFn(.)->Stdlib.Promise.thenResolve(value => Some(value))
              | None => None->Stdlib.Promise.resolve
              }
            })
          }
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          switch input {
          | Some(value) => serializeInner(~struct=innerStruct, ~value)
          | None => Js.Undefined.empty->castAnyToUnknown
          }
        })
      ),
      (),
    )
  }
}

module Deprecated = {
  type tagged = WithoutMessage | WithMessage(string)

  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Deprecated")

  let factory = (innerStruct, ~message as maybeMessage=?, ()) => {
    Option.factory(innerStruct)->Metadata.set(
      ~id=metadataId,
      ~metadata=switch maybeMessage {
      | Some(message) => WithMessage(message)
      | None => WithoutMessage
      },
    )
  }

  let classify = struct => struct->Metadata.get(~id=metadataId)
}

module Array = {
  let factory = innerStruct => {
    make(
      ~name=`Array`,
      ~tagged=Array(innerStruct->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if Js.Array2.isArray(input) === false {
            raiseUnexpectedTypeError(~input, ~struct)
          } else {
            input
          }
        })

        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newArray = []
            for idx in 0 to input->Js.Array2.length - 1 {
              let innerData = input->Js.Array2.unsafe_get(idx)
              try {
                let value = fn(. innerData)
                newArray->Js.Array2.push(value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                  ),
                )
              }
            }
            newArray
          })
        }

        switch innerStruct.parse {
        | NoOperation => ()
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) =>
          planSyncTransformation(fn)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
            input
            ->Js.Array2.mapi(
              (asyncFn, idx) => {
                asyncFn(.)->Stdlib.Promise.catch(
                  exn => {
                    switch exn {
                    | Error.Internal.Exception(internalError) =>
                      Error.Internal.Exception(
                        internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                      )
                    | _ => exn
                    }->raise
                  },
                )
              },
            )
            ->Stdlib.Promise.all
            ->Obj.magic
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct.serialize {
        | NoOperation => ()
        | SyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newArray = []
            for idx in 0 to input->Js.Array2.length - 1 {
              let innerData = input->Js.Array2.unsafe_get(idx)
              try {
                let value = fn(. innerData)
                newArray->Js.Array2.push(value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                  ),
                )
              }
            }
            newArray
          })
        | AsyncOperation(_) => Error.Unreachable.panic()
        }
      }),
      (),
    )
  }

  let min = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length < length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Array must be ${length->Js.Int.toString} or more items long`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let max = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length > length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Array must be ${length->Js.Int.toString} or fewer items long`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }

  let length = (struct, ~message as maybeMessage=?, length) => {
    let refiner = value => {
      if value->Js.Array2.length !== length {
        Error.raise(
          maybeMessage->Stdlib.Option.getWithDefault(
            `Array must be exactly ${length->Js.Int.toString} items long`,
          ),
        )
      }
    }
    struct->refine(~parser=refiner, ~serializer=refiner, ())
  }
}

module Dict = {
  let factory = innerStruct => {
    make(
      ~name=`Dict`,
      ~tagged=Dict(innerStruct->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
        let planSyncTransformation = fn => {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newDict = Js.Dict.empty()
            let keys = input->Js.Dict.keys
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Dict.unsafeGet(key)
              try {
                let value = fn(. innerData)
                newDict->Js.Dict.set(key, value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
              }
            }
            newDict
          })
        }

        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          if input->Stdlib.Object.test === false {
            raiseUnexpectedTypeError(~input, ~struct)
          } else {
            input
          }
        })

        switch innerStruct.parse {
        | NoOperation => ()
        | SyncOperation(fn) => planSyncTransformation(fn)
        | AsyncOperation(fn) =>
          planSyncTransformation(fn)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
            let keys = input->Js.Dict.keys
            keys
            ->Js.Array2.map(
              key => {
                let asyncFn = input->Js.Dict.unsafeGet(key)
                try {
                  asyncFn(.)->Stdlib.Promise.catch(
                    exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(internalError->Error.Internal.prependLocation(key))
                      | _ => exn
                      }->raise
                    },
                  )
                } catch {
                | Error.Internal.Exception(internalError) =>
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(key),
                  )->raise
                }
              },
            )
            ->Stdlib.Promise.all
            ->Stdlib.Promise.thenResolve(
              values => {
                let tempDict = Js.Dict.empty()
                values->Js.Array2.forEachi(
                  (value, idx) => {
                    let key = keys->Js.Array2.unsafe_get(idx)
                    tempDict->Js.Dict.set(key, value)
                  },
                )
                tempDict
              },
            )
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct.serialize {
        | NoOperation => ()
        | SyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let newDict = Js.Dict.empty()
            let keys = input->Js.Dict.keys
            for idx in 0 to keys->Js.Array2.length - 1 {
              let key = keys->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Dict.unsafeGet(key)
              try {
                let value = fn(. innerData)
                newDict->Js.Dict.set(key, value)->ignore
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(Error.Internal.Exception(internalError->Error.Internal.prependLocation(key)))
              }
            }
            newDict
          })
        | AsyncOperation(_) => Error.Unreachable.panic()
        }
      }),
      (),
    )
  }
}

module Defaulted = {
  type tagged = WithDefaultValue(unknown)

  let metadataId = Metadata.Id.make(~namespace="rescript-struct", ~name="Defaulted")

  let factory = (innerStruct, defaultValue) => {
    make(
      ~name=innerStruct.name,
      ~tagged=innerStruct.tagged,
      ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        switch innerStruct.parse {
        | NoOperation =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            input->castUnknownToAny->Stdlib.Option.getWithDefault(defaultValue)
          })
        | SyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            fn(. input)->castUnknownToAny->Stdlib.Option.getWithDefault(defaultValue)
          })
        | AsyncOperation(fn) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(fn->Stdlib.Fn.castToCurried)
          ctx->TransformationFactory.Ctx.planAsyncTransformation(asyncFn => {
            asyncFn(.)->Stdlib.Promise.thenResolve(
              value => {
                value->castUnknownToAny->Stdlib.Option.getWithDefault(defaultValue)
              },
            )
          })
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) => {
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          serializeInner(~struct=innerStruct, ~value=Some(input))
        })
      }),
      (),
    )->Metadata.set(~id=metadataId, ~metadata=WithDefaultValue(defaultValue->castAnyToUnknown))
  }

  let classify = struct => struct->Metadata.get(~id=metadataId)
}

module Tuple = {
  let factory = (
    () => {
      let structs = Stdlib.Fn.getArguments()
      let numberOfStructs = structs->Js.Array2.length

      make(
        ~name="Tuple",
        ~tagged=Tuple(structs),
        ~parseTransformationFactory=TransformationFactory.make((. ~ctx, ~struct) => {
          let noopOps = []
          let syncOps = []
          let asyncOps = []
          for idx in 0 to structs->Js.Array2.length - 1 {
            let innerStruct = structs->Js.Array2.unsafe_get(idx)
            switch innerStruct.parse {
            | NoOperation => noopOps->Js.Array2.push(idx)->ignore
            | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
            | AsyncOperation(fn) => {
                syncOps->Js.Array2.push((idx, fn->Obj.magic))->ignore
                asyncOps->Js.Array2.push(idx)->ignore
              }
            }
          }
          let withAsyncOps = asyncOps->Js.Array2.length > 0

          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            switch Js.Array2.isArray(input) {
            | true =>
              let numberOfInputItems = input->Js.Array2.length
              if numberOfStructs !== numberOfInputItems {
                Error.Internal.raise(
                  TupleSize({
                    expected: numberOfStructs,
                    received: numberOfInputItems,
                  }),
                )
              }
            | false => raiseUnexpectedTypeError(~input, ~struct)
            }

            let newArray = []

            for idx in 0 to syncOps->Js.Array2.length - 1 {
              let (originalIdx, fn) = syncOps->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Array2.unsafe_get(originalIdx)
              try {
                let value = fn(. innerData)
                newArray->Stdlib.Array.set(originalIdx, value)
              } catch {
              | Error.Internal.Exception(internalError) =>
                raise(
                  Error.Internal.Exception(
                    internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                  ),
                )
              }
            }

            for idx in 0 to noopOps->Js.Array2.length - 1 {
              let originalIdx = noopOps->Js.Array2.unsafe_get(idx)
              let innerData = input->Js.Array2.unsafe_get(originalIdx)
              newArray->Stdlib.Array.set(originalIdx, innerData)
            }

            switch withAsyncOps {
            | true => newArray->castAnyToUnknown
            | false =>
              switch numberOfStructs {
              | 0 => ()->castAnyToUnknown
              | 1 => newArray->Js.Array2.unsafe_get(0)->castAnyToUnknown
              | _ => newArray->castAnyToUnknown
              }
            }
          })

          if withAsyncOps {
            ctx->TransformationFactory.Ctx.planAsyncTransformation(tempArray => {
              asyncOps
              ->Js.Array2.map(
                originalIdx => {
                  (
                    tempArray->castUnknownToAny->Js.Array2.unsafe_get(originalIdx)->Obj.magic
                  )(.)->Stdlib.Promise.catch(
                    exn => {
                      switch exn {
                      | Error.Internal.Exception(internalError) =>
                        Error.Internal.Exception(
                          internalError->Error.Internal.prependLocation(
                            originalIdx->Js.Int.toString,
                          ),
                        )
                      | _ => exn
                      }->raise
                    },
                  )
                },
              )
              ->Stdlib.Promise.all
              ->Stdlib.Promise.thenResolve(
                values => {
                  values->Js.Array2.forEachi(
                    (value, idx) => {
                      let originalIdx = asyncOps->Js.Array2.unsafe_get(idx)
                      tempArray->castUnknownToAny->Stdlib.Array.set(originalIdx, value)
                    },
                  )
                  tempArray->castUnknownToAny->Stdlib.Array.toTuple
                },
              )
            })
          }
        }),
        ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let inputArray = numberOfStructs === 1 ? [input] : input->Obj.magic

            let newArray = []
            for idx in 0 to numberOfStructs - 1 {
              let innerData = inputArray->Js.Array2.unsafe_get(idx)
              let innerStruct = structs->Js.Array.unsafe_get(idx)
              switch innerStruct.serialize {
              | NoOperation => newArray->Js.Array2.push(innerData)->ignore
              | SyncOperation(fn) =>
                try {
                  let value = fn(. innerData)
                  newArray->Js.Array2.push(value)->ignore
                } catch {
                | Error.Internal.Exception(internalError) =>
                  raise(
                    Error.Internal.Exception(
                      internalError->Error.Internal.prependLocation(idx->Js.Int.toString),
                    ),
                  )
                }
              | AsyncOperation(_) => Error.Unreachable.panic()
              }
            }
            newArray
          })
        ),
        (),
      )
    }
  )->Obj.magic
}

module Union = {
  exception HackyValidValue(unknown)

  let factory = structs => {
    if structs->Js.Array2.length < 2 {
      Error.UnionLackingStructs.panic()
    }

    make(
      ~name=`Union`,
      ~tagged=Union(structs->Obj.magic),
      ~parseTransformationFactory=TransformationFactory.make((
        . ~ctx,
        ~struct as compilingStruct,
      ) => {
        let structs = compilingStruct->classify->unsafeGetVariantPayload

        let noopOps = []
        let syncOps = []
        let asyncOps = []
        for idx in 0 to structs->Js.Array2.length - 1 {
          let innerStruct = structs->Js.Array2.unsafe_get(idx)
          switch innerStruct.parse {
          | NoOperation => noopOps->Js.Array2.push()->ignore
          | SyncOperation(fn) => syncOps->Js.Array2.push((idx, fn))->ignore
          | AsyncOperation(fn) => asyncOps->Js.Array2.push((idx, fn))->ignore
          }
        }
        let withAsyncOps = asyncOps->Js.Array2.length > 0

        if noopOps->Js.Array2.length === 0 {
          ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
            let idxRef = ref(0)
            let errorsRef = ref([])
            let maybeNewValueRef = ref(None)
            while (
              idxRef.contents < syncOps->Js.Array2.length && maybeNewValueRef.contents === None
            ) {
              let idx = idxRef.contents
              let (originalIdx, fn) = syncOps->Js.Array2.unsafe_get(idx)
              try {
                let newValue = fn(. input)
                maybeNewValueRef.contents = Some(newValue)
              } catch {
              | Error.Internal.Exception(internalError) => {
                  errorsRef.contents->Stdlib.Array.set(originalIdx, internalError)
                  idxRef.contents = idxRef.contents->Stdlib.Int.plus(1)
                }
              }
            }
            switch (maybeNewValueRef.contents, withAsyncOps) {
            | (Some(newValue), false) => newValue
            | (None, false) =>
              Error.Internal.raise(
                InvalidUnion(errorsRef.contents->Js.Array2.map(Error.Internal.toParseError)),
              )
            | (maybeSyncValue, true) =>
              {
                "maybeSyncValue": maybeSyncValue,
                "tempErrors": errorsRef.contents,
                "originalInput": input,
              }->castAnyToUnknown
            }
          })

          if withAsyncOps {
            ctx->TransformationFactory.Ctx.planAsyncTransformation(input => {
              switch input["maybeSyncValue"] {
              | Some(syncValue) => syncValue->Stdlib.Promise.resolve
              | None =>
                asyncOps
                ->Js.Array2.map(
                  ((originalIdx, fn)) => {
                    try {
                      fn(. input["originalInput"])(.)->Stdlib.Promise.thenResolveWithCatch(
                        value => raise(HackyValidValue(value)),
                        exn =>
                          switch exn {
                          | Error.Internal.Exception(internalError) =>
                            input["tempErrors"]->Stdlib.Array.set(originalIdx, internalError)
                          | _ => raise(exn)
                          },
                      )
                    } catch {
                    | Error.Internal.Exception(internalError) =>
                      input["tempErrors"]
                      ->Stdlib.Array.set(originalIdx, internalError)
                      ->Stdlib.Promise.resolve
                    }
                  },
                )
                ->Stdlib.Promise.all
                ->Stdlib.Promise.thenResolveWithCatch(
                  _ => {
                    Error.Internal.raise(
                      InvalidUnion(input["tempErrors"]->Js.Array2.map(Error.Internal.toParseError)),
                    )
                  },
                  exn => {
                    switch exn {
                    | HackyValidValue(value) => value
                    | _ => raise(exn)
                    }
                  },
                )
              }
            })
          }
        }
      }),
      ~serializeTransformationFactory=TransformationFactory.make((. ~ctx, ~struct as _) =>
        ctx->TransformationFactory.Ctx.planSyncTransformation(input => {
          let idxRef = ref(0)
          let maybeLastErrorRef = ref(None)
          let maybeNewValueRef = ref(None)
          while idxRef.contents < structs->Js.Array2.length && maybeNewValueRef.contents === None {
            let idx = idxRef.contents
            let innerStruct = structs->Js.Array2.unsafe_get(idx)->Obj.magic
            try {
              let newValue = serializeInner(~struct=innerStruct, ~value=input)
              maybeNewValueRef.contents = Some(newValue)
            } catch {
            | Error.Internal.Exception(internalError) => {
                maybeLastErrorRef.contents = Some(internalError)
                idxRef.contents = idxRef.contents->Stdlib.Int.plus(1)
              }
            }
          }
          switch maybeNewValueRef.contents {
          | Some(ok) => ok
          | None =>
            switch maybeLastErrorRef.contents {
            | Some(error) => raise(Error.Internal.Exception(error))
            | None => %raw(`undefined`)
            }
          }
        })
      ),
      (),
    )
  }
}

module Result = {
  let getExn = result => {
    switch result {
    | Ok(value) => value
    | Error(error) => Error.panic(error->Error.toString)
    }
  }

  let mapErrorToString = result => {
    result->Stdlib.Result.mapError(Error.toString)
  }
}

let field = Object2.field
let object = Object2.factory
let object0 = Object.factory
let object1 = Object.factory
let object2 = Object.factory
let object3 = Object.factory
let object4 = Object.factory
let object5 = Object.factory
let object6 = Object.factory
let object7 = Object.factory
let object8 = Object.factory
let object9 = Object.factory
let object10 = Object.factory
let never = Never.factory
let unknown = Unknown.factory
let string = String.factory
let bool = Bool.factory
let int = Int.factory
let float = Float.factory
let null = Null.factory
let option = Option.factory
let deprecated = Deprecated.factory
let array = Array.factory
let dict = Dict.factory
let defaulted = Defaulted.factory
let literal = Literal.factory
let literalVariant = Literal.Variant.factory
let date = Date.factory
let tuple0 = Tuple.factory
let tuple1 = Tuple.factory
let tuple2 = Tuple.factory
let tuple3 = Tuple.factory
let tuple4 = Tuple.factory
let tuple5 = Tuple.factory
let tuple6 = Tuple.factory
let tuple7 = Tuple.factory
let tuple8 = Tuple.factory
let tuple9 = Tuple.factory
let tuple10 = Tuple.factory
let union = Union.factory
let json = Json.factory
