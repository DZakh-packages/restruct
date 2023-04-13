// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var S$RescriptStruct = require("./S.bs.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

class RescriptStructError extends Error {
      constructor(message) {
        super(message);
        this.name = "RescriptStructError";
      }
    }
    exports.RescriptStructError = RescriptStructError
;

function fromOk(value) {
  return {
          success: true,
          value: value
        };
}

function fromError(error) {
  return {
          success: false,
          error: error
        };
}

var structOperations = {};

function fail(reason) {
  return S$RescriptStruct.fail(undefined, reason);
}

function parse(data) {
  var struct = this;
  try {
    return fromOk(S$RescriptStruct.parseAnyOrRaiseWith(data, struct));
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === S$RescriptStruct.Raised) {
      return fromError(new RescriptStructError(S$RescriptStruct.$$Error.toString(error._1)));
    }
    throw error;
  }
}

function parseOrThrow(data) {
  var struct = this;
  try {
    return S$RescriptStruct.parseAnyOrRaiseWith(data, struct);
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === S$RescriptStruct.Raised) {
      throw new RescriptStructError(S$RescriptStruct.$$Error.toString(error._1));
    }
    throw error;
  }
}

function parseAsync(data) {
  var struct = this;
  return S$RescriptStruct.parseAnyAsyncWith(data, struct).then(function (result) {
              if (result.TAG === "Ok") {
                return fromOk(result._0);
              } else {
                return fromError(new RescriptStructError(S$RescriptStruct.$$Error.toString(result._0)));
              }
            });
}

function serialize(value) {
  var struct = this;
  try {
    return fromOk(S$RescriptStruct.serializeToUnknownOrRaiseWith(value, struct));
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === S$RescriptStruct.Raised) {
      return fromError(new RescriptStructError(S$RescriptStruct.$$Error.toString(error._1)));
    }
    throw error;
  }
}

function serializeOrThrow(value) {
  var struct = this;
  try {
    return S$RescriptStruct.serializeToUnknownOrRaiseWith(value, struct);
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === S$RescriptStruct.Raised) {
      throw new RescriptStructError(S$RescriptStruct.$$Error.toString(error._1));
    }
    throw error;
  }
}

function transform(parser, serializer) {
  var struct = this;
  var struct$1 = S$RescriptStruct.transform(struct, parser, undefined, serializer, undefined);
  return Object.assign(struct$1, structOperations);
}

function refine(parser, serializer) {
  var struct = this;
  var struct$1 = S$RescriptStruct.refine(struct, parser, undefined, serializer, undefined);
  return Object.assign(struct$1, structOperations);
}

function asyncRefine(parser) {
  var struct = this;
  var struct$1 = S$RescriptStruct.refine(struct, undefined, parser, undefined, undefined);
  return Object.assign(struct$1, structOperations);
}

function describe(description) {
  var struct = this;
  var struct$1 = S$RescriptStruct.describe(struct, description);
  return Object.assign(struct$1, structOperations);
}

function description(param) {
  return S$RescriptStruct.description(this);
}

function $$default(def) {
  var struct = this;
  var struct$1 = S$RescriptStruct.$$default(struct, def);
  return Object.assign(struct$1, structOperations);
}

function string(param) {
  var struct = S$RescriptStruct.string(undefined);
  return Object.assign(struct, structOperations);
}

function $$boolean(param) {
  var struct = S$RescriptStruct.bool(undefined);
  return Object.assign(struct, structOperations);
}

function integer(param) {
  var struct = S$RescriptStruct.$$int(undefined);
  return Object.assign(struct, structOperations);
}

function number(param) {
  var struct = S$RescriptStruct.$$float(undefined);
  return Object.assign(struct, structOperations);
}

function never(param) {
  var struct = S$RescriptStruct.never(undefined);
  return Object.assign(struct, structOperations);
}

function unknown(param) {
  var struct = S$RescriptStruct.unknown(undefined);
  return Object.assign(struct, structOperations);
}

function optional(struct) {
  var struct$1 = S$RescriptStruct.option(struct);
  return Object.assign(struct$1, structOperations);
}

function nullable(struct) {
  var struct$1 = S$RescriptStruct.$$null(struct);
  return Object.assign(struct$1, structOperations);
}

function array(struct) {
  var struct$1 = S$RescriptStruct.array(struct);
  return Object.assign(struct$1, structOperations);
}

function record(struct) {
  var struct$1 = S$RescriptStruct.dict(struct);
  return Object.assign(struct$1, structOperations);
}

function json(struct) {
  var struct$1 = S$RescriptStruct.json(struct);
  return Object.assign(struct$1, structOperations);
}

function union(structs) {
  var struct = S$RescriptStruct.union(structs);
  return Object.assign(struct, structOperations);
}

function tuple(structs) {
  var struct = S$RescriptStruct.Tuple.factory.apply(null, structs);
  return Object.assign(struct, structOperations);
}

function literal(value) {
  var taggedLiteral = typeof value === "string" ? ({
        TAG: "String",
        _0: value
      }) : (
      typeof value === "boolean" ? ({
            TAG: "Bool",
            _0: value
          }) : (
          typeof value === "number" ? (
              Number.isNaN(value) ? Js_exn.raiseError("[rescript-struct] Failed to create a NaN literal struct. Use S.nan instead.") : ({
                    TAG: "Float",
                    _0: value
                  })
            ) : (
              value === null ? "EmptyNull" : (
                  value === undefined ? "EmptyOption" : Js_exn.raiseError("[rescript-struct] The value provided to literal struct factory is not supported.")
                )
            )
        )
    );
  var struct = S$RescriptStruct.literal(taggedLiteral);
  return Object.assign(struct, structOperations);
}

function nan(param) {
  var struct = S$RescriptStruct.literal("NaN");
  return Object.assign(struct, structOperations);
}

function custom(name, parser, serializer) {
  var struct = S$RescriptStruct.custom(name, parser, undefined, serializer, undefined);
  return Object.assign(struct, structOperations);
}

Object.assign(structOperations, {
      parse: parse,
      parseOrThrow: parseOrThrow,
      parseAsync: parseAsync,
      serialize: serialize,
      serializeOrThrow: serializeOrThrow,
      transform: transform,
      refine: refine,
      asyncRefine: asyncRefine,
      optional: (function (param) {
          return optional(this);
        }),
      nullable: (function (param) {
          return nullable(this);
        }),
      describe: describe,
      description: description,
      default: $$default
    });

var objectStructOperations = {};

function strict(param) {
  var struct = this;
  return Object.assign(S$RescriptStruct.$$Object.strict(struct), objectStructOperations);
}

function strip(param) {
  var struct = this;
  return Object.assign(S$RescriptStruct.$$Object.strip(struct), objectStructOperations);
}

function factory(definer) {
  return Object.assign(S$RescriptStruct.object(function (o) {
                  var definition = {};
                  var fieldNames = Object.keys(definer);
                  for(var idx = 0 ,idx_finish = fieldNames.length; idx < idx_finish; ++idx){
                    var fieldName = fieldNames[idx];
                    var struct = definer[fieldName];
                    definition[fieldName] = S$RescriptStruct.field(o, fieldName, struct);
                  }
                  return definition;
                }), objectStructOperations);
}

Object.assign(objectStructOperations, structOperations);

Object.assign(objectStructOperations, {
      strict: strict,
      strip: strip
    });

var $$Error = {};

var Result = {};

var $$Object = {
  factory: factory
};

exports.$$Error = $$Error;
exports.Result = Result;
exports.fail = fail;
exports.string = string;
exports.$$boolean = $$boolean;
exports.integer = integer;
exports.number = number;
exports.never = never;
exports.unknown = unknown;
exports.optional = optional;
exports.nullable = nullable;
exports.array = array;
exports.record = record;
exports.json = json;
exports.union = union;
exports.literal = literal;
exports.nan = nan;
exports.tuple = tuple;
exports.custom = custom;
exports.$$Object = $$Object;
/*  Not a pure module */
