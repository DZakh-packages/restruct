const S_Js = require("./S_Js.bs.js");
const S = require("./S.bs.js");

exports.StructError = S_Js.ReScriptStructError;
exports.string = S_Js.string;
exports.boolean = S_Js.$$boolean;
exports.integer = S_Js.integer;
exports.number = S_Js.number;
exports.never = S_Js.never;
exports.unknown = S_Js.unknown;
exports.optional = S_Js.optional;
exports.nullable = S_Js.nullable;
exports.array = S_Js.array;
exports.record = S_Js.record;
exports.json = S_Js.json;
exports.union = S_Js.union;
exports.object = S_Js.$$Object.factory;
exports.custom = S_Js.custom;
exports.raiseError = S.$$Error.raise;
