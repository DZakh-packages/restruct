// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";

function cleanUpTransformationFactories(struct) {
  var fields = [
    "pf",
    "sf"
  ];
  var dict = Object.assign({}, struct);
  fields.forEach(function (field) {
        Js_dict.unsafeDeleteKey(dict, field);
      });
  return dict;
}

function assertEqualStructs(t, s1, s2, message, param) {
  t.deepEqual(cleanUpTransformationFactories(s1), cleanUpTransformationFactories(s2), message !== undefined ? Caml_option.valFromOption(message) : undefined);
}

export {
  assertEqualStructs ,
}
/* No side effect */
