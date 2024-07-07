// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Benchmark from "benchmark";
import * as S$RescriptSchema from "rescript-schema/src/S.bs.mjs";

function addWithPrepare(suite, name, fn) {
  return suite.add(name, fn());
}

function run(suite) {
  suite.on("cycle", (function ($$event) {
            console.log($$event.target.toString());
          })).run();
}

function makeTestObject() {
  return (Object.freeze({
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
  }));
}

function makeAdvancedObjectSchema() {
  return S$RescriptSchema.object(function (s) {
              return {
                      number: s.f("number", S$RescriptSchema.$$float),
                      negNumber: s.f("negNumber", S$RescriptSchema.$$float),
                      maxNumber: s.f("maxNumber", S$RescriptSchema.$$float),
                      string: s.f("string", S$RescriptSchema.string),
                      longString: s.f("longString", S$RescriptSchema.string),
                      boolean: s.f("boolean", S$RescriptSchema.bool),
                      deeplyNested: s.f("deeplyNested", S$RescriptSchema.object(function (s) {
                                return {
                                        foo: s.f("foo", S$RescriptSchema.string),
                                        num: s.f("num", S$RescriptSchema.$$float),
                                        bool: s.f("bool", S$RescriptSchema.bool)
                                      };
                              }))
                    };
            });
}

function makeAdvancedStrictObjectSchema() {
  return S$RescriptSchema.$$Object.strict(S$RescriptSchema.object(function (s) {
                  return {
                          number: s.f("number", S$RescriptSchema.$$float),
                          negNumber: s.f("negNumber", S$RescriptSchema.$$float),
                          maxNumber: s.f("maxNumber", S$RescriptSchema.$$float),
                          string: s.f("string", S$RescriptSchema.string),
                          longString: s.f("longString", S$RescriptSchema.string),
                          boolean: s.f("boolean", S$RescriptSchema.bool),
                          deeplyNested: s.f("deeplyNested", S$RescriptSchema.$$Object.strict(S$RescriptSchema.object(function (s) {
                                        return {
                                                foo: s.f("foo", S$RescriptSchema.string),
                                                num: s.f("num", S$RescriptSchema.$$float),
                                                bool: s.f("bool", S$RescriptSchema.bool)
                                              };
                                      })))
                        };
                }));
}

var data = makeTestObject();

console.time("makeAdvancedObjectSchema");

var schema = makeAdvancedObjectSchema();

console.timeEnd("makeAdvancedObjectSchema");

console.time("parseAnyWith: 1");

S$RescriptSchema.parseAnyWith(data, schema);

console.timeEnd("parseAnyWith: 1");

console.time("parseAnyWith: 2");

S$RescriptSchema.parseAnyWith(data, schema);

console.timeEnd("parseAnyWith: 2");

console.time("parseAnyWith: 3");

S$RescriptSchema.parseAnyWith(data, schema);

console.timeEnd("parseAnyWith: 3");

console.time("serializeWith: 1");

S$RescriptSchema.serializeWith(data, schema);

console.timeEnd("serializeWith: 1");

console.time("serializeWith: 2");

S$RescriptSchema.serializeWith(data, schema);

console.timeEnd("serializeWith: 2");

console.time("serializeWith: 3");

S$RescriptSchema.serializeWith(data, schema);

console.timeEnd("serializeWith: 3");

console.time("S.Error.make");

S$RescriptSchema.$$Error.make({
      TAG: "OperationFailed",
      _0: "Should be positive"
    }, "Parse", S$RescriptSchema.Path.empty);

console.timeEnd("S.Error.make");

run(addWithPrepare(addWithPrepare(addWithPrepare(addWithPrepare(addWithPrepare(addWithPrepare(addWithPrepare(addWithPrepare(new (Benchmark.default.Suite)(), "Parse string", (function () {
                                          return function () {
                                            return S$RescriptSchema.parseAnyOrRaiseWith("Hello world!", S$RescriptSchema.string);
                                          };
                                        })), "Serialize string", (function () {
                                      return function () {
                                        return S$RescriptSchema.serializeOrRaiseWith("Hello world!", S$RescriptSchema.string);
                                      };
                                    })).add("Advanced object schema factory", makeAdvancedObjectSchema), "Parse advanced object", (function () {
                                var schema = makeAdvancedObjectSchema();
                                var data = makeTestObject();
                                return function () {
                                  return S$RescriptSchema.parseAnyOrRaiseWith(data, schema);
                                };
                              })), "Assert advanced object", (function () {
                            var schema = makeAdvancedObjectSchema();
                            var data = makeTestObject();
                            return function () {
                              S$RescriptSchema.assertOrRaiseWith(data, schema);
                            };
                          })), "Create and parse advanced object", (function () {
                        var data = makeTestObject();
                        return function () {
                          var schema = makeAdvancedObjectSchema();
                          return S$RescriptSchema.parseAnyOrRaiseWith(data, schema);
                        };
                      })), "Parse advanced strict object", (function () {
                    var schema = makeAdvancedStrictObjectSchema();
                    var data = makeTestObject();
                    return function () {
                      return S$RescriptSchema.parseAnyOrRaiseWith(data, schema);
                    };
                  })), "Assert advanced strict object", (function () {
                var schema = makeAdvancedStrictObjectSchema();
                var data = makeTestObject();
                return function () {
                  S$RescriptSchema.assertOrRaiseWith(data, schema);
                };
              })), "Serialize advanced object", (function () {
            var schema = makeAdvancedObjectSchema();
            var data = makeTestObject();
            return function () {
              return S$RescriptSchema.serializeOrRaiseWith(data, schema);
            };
          })));

export {
  
}
/* data Not a pure module */
