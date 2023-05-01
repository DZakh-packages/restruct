// Generated by ReScript, PLEASE EDIT WITH CARE

import Ava from "ava";
import * as TestUtils from "./TestUtils.bs.mjs";
import * as S$RescriptStruct from "rescript-struct/src/S.bs.mjs";

var myStringStruct = S$RescriptStruct.string(undefined);

Ava("String struct", (function (t) {
        TestUtils.assertEqualStructs(t, myStringStruct, S$RescriptStruct.string(undefined), undefined, undefined);
      }));

var myIntStruct = S$RescriptStruct.$$int(undefined);

Ava("Int struct", (function (t) {
        TestUtils.assertEqualStructs(t, myIntStruct, S$RescriptStruct.$$int(undefined), undefined, undefined);
      }));

var myFloatStruct = S$RescriptStruct.$$float(undefined);

Ava("Float struct", (function (t) {
        TestUtils.assertEqualStructs(t, myFloatStruct, S$RescriptStruct.$$float(undefined), undefined, undefined);
      }));

var myBoolStruct = S$RescriptStruct.bool(undefined);

Ava("Bool struct", (function (t) {
        TestUtils.assertEqualStructs(t, myBoolStruct, S$RescriptStruct.bool(undefined), undefined, undefined);
      }));

var myUnitStruct = S$RescriptStruct.unit(undefined);

Ava("Unit struct", (function (t) {
        TestUtils.assertEqualStructs(t, myUnitStruct, S$RescriptStruct.unit(undefined), undefined, undefined);
      }));

var myUnknownStruct = S$RescriptStruct.unknown(undefined);

Ava("Unknown struct", (function (t) {
        TestUtils.assertEqualStructs(t, myUnknownStruct, S$RescriptStruct.unknown(undefined), undefined, undefined);
      }));

var myNeverStruct = S$RescriptStruct.never(undefined);

Ava("Never struct", (function (t) {
        TestUtils.assertEqualStructs(t, myNeverStruct, S$RescriptStruct.never(undefined), undefined, undefined);
      }));

var myOptionOfStringStruct = S$RescriptStruct.option(S$RescriptStruct.string(undefined));

Ava("Option of string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myOptionOfStringStruct, S$RescriptStruct.option(S$RescriptStruct.string(undefined)), undefined, undefined);
      }));

var myArrayOfStringStruct = S$RescriptStruct.array(S$RescriptStruct.string(undefined));

Ava("Array of string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myArrayOfStringStruct, S$RescriptStruct.array(S$RescriptStruct.string(undefined)), undefined, undefined);
      }));

var myListOfStringStruct = S$RescriptStruct.list(S$RescriptStruct.string(undefined));

Ava("List of string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myListOfStringStruct, S$RescriptStruct.list(S$RescriptStruct.string(undefined)), undefined, undefined);
      }));

var myDictOfStringStruct = S$RescriptStruct.dict(S$RescriptStruct.string(undefined));

Ava("Dict of string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myDictOfStringStruct, S$RescriptStruct.dict(S$RescriptStruct.string(undefined)), undefined, undefined);
      }));

var myDictOfStringFromCoreStruct = S$RescriptStruct.dict(S$RescriptStruct.string(undefined));

Ava("Dict of string struct from Core", (function (t) {
        TestUtils.assertEqualStructs(t, myDictOfStringFromCoreStruct, S$RescriptStruct.dict(S$RescriptStruct.string(undefined)), undefined, undefined);
      }));

var myJsonStruct = S$RescriptStruct.jsonable(undefined);

Ava("Json struct", (function (t) {
        TestUtils.assertEqualStructs(t, myJsonStruct, S$RescriptStruct.jsonable(undefined), undefined, undefined);
      }));

var myJsonFromCoreStruct = S$RescriptStruct.jsonable(undefined);

Ava("Json struct from Core", (function (t) {
        TestUtils.assertEqualStructs(t, myJsonFromCoreStruct, S$RescriptStruct.jsonable(undefined), undefined, undefined);
      }));

var myTupleStruct = S$RescriptStruct.Tuple.factory([
      S$RescriptStruct.string(undefined),
      S$RescriptStruct.$$int(undefined)
    ]);

Ava("Tuple struct", (function (t) {
        TestUtils.assertEqualStructs(t, myTupleStruct, S$RescriptStruct.tuple2(S$RescriptStruct.string(undefined), S$RescriptStruct.$$int(undefined)), undefined, undefined);
      }));

var myBigTupleStruct = S$RescriptStruct.Tuple.factory([
      S$RescriptStruct.string(undefined),
      S$RescriptStruct.string(undefined),
      S$RescriptStruct.string(undefined),
      S$RescriptStruct.$$int(undefined),
      S$RescriptStruct.$$int(undefined),
      S$RescriptStruct.$$int(undefined),
      S$RescriptStruct.$$float(undefined),
      S$RescriptStruct.$$float(undefined),
      S$RescriptStruct.$$float(undefined),
      S$RescriptStruct.bool(undefined),
      S$RescriptStruct.bool(undefined),
      S$RescriptStruct.bool(undefined)
    ]);

Ava("Big tuple struct", (function (t) {
        TestUtils.assertEqualStructs(t, myBigTupleStruct, S$RescriptStruct.Tuple.factory([
                  S$RescriptStruct.string(undefined),
                  S$RescriptStruct.string(undefined),
                  S$RescriptStruct.string(undefined),
                  S$RescriptStruct.$$int(undefined),
                  S$RescriptStruct.$$int(undefined),
                  S$RescriptStruct.$$int(undefined),
                  S$RescriptStruct.$$float(undefined),
                  S$RescriptStruct.$$float(undefined),
                  S$RescriptStruct.$$float(undefined),
                  S$RescriptStruct.bool(undefined),
                  S$RescriptStruct.bool(undefined),
                  S$RescriptStruct.bool(undefined)
                ]), undefined, undefined);
      }));

var myCustomStringStruct = S$RescriptStruct.$$String.email(S$RescriptStruct.string(undefined), undefined, undefined);

Ava("Custom string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myCustomStringStruct, S$RescriptStruct.$$String.email(S$RescriptStruct.string(undefined), undefined, undefined), undefined, undefined);
      }));

var myCustomLiteralStringStruct = S$RescriptStruct.$$String.email(S$RescriptStruct.literal({
          TAG: "String",
          _0: "123"
        }), undefined, undefined);

Ava("Custom litaral string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myCustomLiteralStringStruct, S$RescriptStruct.$$String.email(S$RescriptStruct.literal({
                      TAG: "String",
                      _0: "123"
                    }), undefined, undefined), undefined, undefined);
      }));

var myNullOfStringStruct = S$RescriptStruct.$$null(S$RescriptStruct.string(undefined));

Ava("Null of string struct", (function (t) {
        TestUtils.assertEqualStructs(t, myNullOfStringStruct, S$RescriptStruct.$$null(S$RescriptStruct.string(undefined)), undefined, undefined);
      }));

export {
  myStringStruct ,
  myIntStruct ,
  myFloatStruct ,
  myBoolStruct ,
  myUnitStruct ,
  myUnknownStruct ,
  myNeverStruct ,
  myOptionOfStringStruct ,
  myArrayOfStringStruct ,
  myListOfStringStruct ,
  myDictOfStringStruct ,
  myDictOfStringFromCoreStruct ,
  myJsonStruct ,
  myJsonFromCoreStruct ,
  myTupleStruct ,
  myBigTupleStruct ,
  myCustomStringStruct ,
  myCustomLiteralStringStruct ,
  myNullOfStringStruct ,
}
/* myStringStruct Not a pure module */
