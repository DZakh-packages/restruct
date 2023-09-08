@@uncurried

module Obj = {
  external magic: 'a => 'b = "%identity"
}

module Stdlib = {
  module Promise = {
    type t<+'a> = promise<'a>

    @send
    external thenResolve: (t<'a>, 'a => 'b) => t<'b> = "then"
  }
}

type jsResult<'value>

let toJsResult = (result: result<'value, S.error>): jsResult<'value> => {
  let tmp = result->Obj.magic
  switch result {
  | Ok(value) => {
      tmp["success"] = true
      tmp["value"] = value
    }
  | Error(error) => {
      tmp["success"] = false
      tmp["error"] = error
    }
  }
  let _ = %raw(`delete result.TAG`)
  let _ = %raw(`delete result._0`)
  tmp
}

let transform = (struct, ~parser as maybeParser=?, ~serializer as maybeSerializer=?) => {
  struct->S.transform(s => {
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, s))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, s))
      | None => None
      },
    }
  })
}

let refine = (struct, refiner) => {
  struct->S.refine(s => {
    v => refiner(v, s)
  })
}

let noop = a => a
let asyncParserRefine = (struct, refine) => {
  struct->S.transform(s => {
    {
      asyncParser: v => () => refine(v, s)->Stdlib.Promise.thenResolve(() => v),
      serializer: noop,
    }
  })
}

let optional = (struct, maybeOr) => {
  let struct = S.option(struct)
  switch maybeOr {
  | Some(or) if Js.typeof(or) === "function" => struct->S.Option.getOrWith(or->Obj.magic)->Obj.magic
  | Some(or) => struct->S.Option.getOr(or->Obj.magic)->Obj.magic
  | None => struct
  }
}

let tuple = structs => {
  S.tuple(s => {
    structs->Js.Array2.mapi((struct, idx) => {
      s.item(idx, struct)
    })
  })
}

let custom = (~name, ~parser as maybeParser=?, ~serializer as maybeSerializer=?, ()) => {
  S.custom(name, s => {
    {
      parser: ?switch maybeParser {
      | Some(parser) => Some(v => parser(v, s))
      | None => None
      },
      serializer: ?switch maybeSerializer {
      | Some(serializer) => Some(v => serializer(v, s))
      | None => None
      },
    }
  })
}

let object = definer => {
  S.object(s => {
    let definition = Js.Dict.empty()
    let fieldNames = definer->Js.Dict.keys
    for idx in 0 to fieldNames->Js.Array2.length - 1 {
      let fieldName = fieldNames->Js.Array2.unsafe_get(idx)
      let struct = definer->Js.Dict.unsafeGet(fieldName)
      definition->Js.Dict.set(fieldName, s.field(fieldName, struct))
    }
    definition
  })
}

let parse = (struct, data) => {
  data->S.parseAnyWith(struct)->toJsResult
}

let parseOrThrow = (struct, data) => {
  (struct->Obj.magic)["p"](data)
}

let parseAsync = (struct, data) => {
  data->S.parseAnyAsyncWith(struct)->Stdlib.Promise.thenResolve(toJsResult)
}

let serialize = (struct, value) => {
  value->S.serializeToUnknownWith(struct)->Obj.magic->toJsResult
}

let serializeOrThrow = (struct, value) => {
  (struct->Obj.magic)["s"](value)
}
