// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Caml_exceptions from "rescript/lib/es6/caml_exceptions.js";
import * as S$RescriptSchema from "rescript-schema/src/S.bs.mjs";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";

function unsafeGetVariantPayload(variant) {
  return variant._0;
}

var Test = /* @__PURE__ */Caml_exceptions.create("U.Test");

function raiseTestException() {
  throw {
        RE_EXN_ID: Test,
        Error: new Error()
      };
}

function error(param) {
  return S$RescriptSchema.$$Error.make(param.code, param.operation, param.path);
}

function assertThrowsTestException(t, fn, message, param) {
  try {
    fn();
    return t.fail("Didn't throw");
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn.RE_EXN_ID === Test) {
      t.pass(message !== undefined ? Caml_option.valFromOption(message) : undefined);
      return ;
    } else {
      return t.fail("Thrown another exception");
    }
  }
}

function assertErrorResult(t, result, errorPayload) {
  if (result.TAG === "Ok") {
    return t.fail("Asserted result is not Error.");
  }
  t.is(S$RescriptSchema.$$Error.message(result._0), S$RescriptSchema.$$Error.message(error(errorPayload)), undefined);
}

function cleanUpSchema(schema) {
  var $$new = {};
  Object.entries(schema).forEach(function (param) {
        var value = param[1];
        var key = param[0];
        switch (key) {
          case "definition" :
          case "i" :
              return ;
          default:
            if (typeof value === "function") {
              return ;
            } else {
              if (typeof value === "object" && value !== null) {
                $$new[key] = cleanUpSchema(value);
              } else {
                $$new[key] = value;
              }
              return ;
            }
        }
      });
  return $$new;
}

function unsafeAssertEqualSchemas(t, s1, s2, message) {
  t.deepEqual(cleanUpSchema(s1), cleanUpSchema(s2), message !== undefined ? Caml_option.valFromOption(message) : undefined);
}

function assertCompiledCode(t, schema, op, code, message) {
  var compiledCode;
  if (op === "Assert") {
    try {
      S$RescriptSchema.assertOrRaiseWith(undefined, schema);
    }
    catch (exn){
      
    }
    compiledCode = (schema.assert.toString());
  } else if (op === "Serialize") {
    try {
      S$RescriptSchema.serializeToUnknownOrRaiseWith(undefined, schema);
    }
    catch (exn$1){
      
    }
    compiledCode = (schema.serializeOrThrow.toString());
  } else if (S$RescriptSchema.isAsyncParse(schema)) {
    S$RescriptSchema.parseAsyncInStepsWith(undefined, schema);
    compiledCode = (schema.a.toString());
  } else {
    S$RescriptSchema.parseAnyWith(undefined, schema);
    compiledCode = (schema.parseOrThrow.toString());
  }
  t.is(compiledCode, code, message !== undefined ? Caml_option.valFromOption(message) : undefined);
}

function assertCompiledCodeIsNoop(t, schema, op, message) {
  var compiledCode;
  if (op === "Serialize") {
    try {
      S$RescriptSchema.serializeToUnknownOrRaiseWith(undefined, schema);
    }
    catch (exn){
      
    }
    compiledCode = (schema.serializeOrThrow.toString());
  } else if (S$RescriptSchema.isAsyncParse(schema)) {
    S$RescriptSchema.parseAsyncInStepsWith(undefined, schema);
    compiledCode = (schema.a.toString());
  } else {
    S$RescriptSchema.parseAnyWith(undefined, schema);
    compiledCode = (schema.parseOrThrow.toString());
  }
  t.truthy(compiledCode.startsWith("function noopOperation(i)"), message !== undefined ? Caml_option.valFromOption(message) : undefined);
}

var assertEqualSchemas = unsafeAssertEqualSchemas;

export {
  unsafeGetVariantPayload ,
  Test ,
  raiseTestException ,
  error ,
  assertThrowsTestException ,
  assertErrorResult ,
  cleanUpSchema ,
  unsafeAssertEqualSchemas ,
  assertCompiledCode ,
  assertCompiledCodeIsNoop ,
  assertEqualSchemas ,
}
/* S-RescriptSchema Not a pure module */
