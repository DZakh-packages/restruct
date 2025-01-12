let projectPath = "."
let artifactsPath = NodeJs.Path.join2(projectPath, "packages/artifacts")
let sourePaths = [
  "package.json",
  "node_modules",
  "src",
  "rescript.json",
  "README.md",
  "RescriptSchema.gen.d.ts",
]
let jsInputPath = NodeJs.Path.join2(artifactsPath, "src/S.js")

module Stdlib = {
  module Json = {
    let rec update = (json, path, value) => {
      let dict = switch json->JSON.Decode.object {
      | Some(dict) => dict->Dict.copy
      | None => Dict.make()
      }
      switch path {
      | list{} => value
      | list{key} => {
          dict->Dict.set(key, value)
          dict->JSON.Encode.object
        }
      | list{key, ...path} => {
          dict->Dict.set(
            key,
            dict
            ->Dict.get(key)
            ->Option.getOr(Dict.make()->JSON.Encode.object)
            ->update(path, value),
          )
          dict->JSON.Encode.object
        }
      }
    }
  }
}

module Execa = {
  type returnValue = {stdout: string}
  type options = {env?: dict<string>, cwd?: string}

  @module("execa")
  external sync: (string, array<string>, ~options: options=?, unit) => returnValue = "execaSync"
}

module FsX = {
  type rmSyncOptions = {recursive?: bool, force?: bool}
  @module("fs") external rmSync: (string, rmSyncOptions) => unit = "rmSync"

  type cpSyncOptions = {recursive?: bool}
  @module("fs") external cpSync: (~src: string, ~dest: string, cpSyncOptions) => unit = "cpSync"
}

module Rollup = {
  type internalModuleFormat = [#amd | #cjs | #es | #iife | #system | #umd]
  type moduleFormat = [internalModuleFormat | #commonjs | #esm | #"module" | #systemjs]

  module Plugin = {
    type t
  }

  module ReplacePlugin = {
    type options = {values: dict<string>}
    @module("@rollup/plugin-replace") external make: options => Plugin.t = "default"
  }

  module InputOptions = {
    type t = {
      input?: string,
      @as("external")
      external_?: array<RegExp.t>,
    }
  }

  module OutputOptions = {
    type t = {
      // only needed for Bundle.write
      dir?: string,
      // only needed for Bundle.write
      file?: string,
      format?: moduleFormat,
      exports?: [#default | #named | #none | #auto],
      plugins?: array<Plugin.t>,
    }
  }

  module Output = {
    type t
  }

  module Bundle = {
    type t

    @module("rollup")
    external make: InputOptions.t => promise<t> = "rollup"

    @send
    external write: (t, OutputOptions.t) => promise<Output.t> = "write"

    @send
    external close: t => promise<unit> = "close"
  }
}

if NodeJs.Fs.existsSync(artifactsPath) {
  FsX.rmSync(artifactsPath, {recursive: true, force: true})
}
NodeJs.Fs.mkdirSync(artifactsPath)

sourePaths->Array.forEach(path => {
  FsX.cpSync(
    ~src=NodeJs.Path.join2(projectPath, path),
    ~dest=NodeJs.Path.join2(artifactsPath, path),
    {recursive: true},
  )
})

let updateJsonFile = (~src, ~path, ~value) => {
  let packageJsonData = NodeJs.Fs.readFileSyncWith(
    src,
    {
      encoding: "utf8",
    },
  )
  let packageJson = packageJsonData->NodeJs.Buffer.toString->JSON.parseExn
  let updatedPackageJson =
    packageJson->Stdlib.Json.update(path->List.fromArray, value)->JSON.stringify(~space=2)
  NodeJs.Fs.writeFileSyncWith(
    src,
    updatedPackageJson->NodeJs.Buffer.fromString,
    {
      encoding: "utf8",
    },
  )
}

let _ = Execa.sync("npm", ["run", "res:build"], ~options={cwd: artifactsPath}, ())

let bundle = await Rollup.Bundle.make({input: jsInputPath, external_: [/S_Core\.bs\.mjs/]})
let output: array<Rollup.OutputOptions.t> = [
  {
    file: NodeJs.Path.join2(artifactsPath, "dist/S.js"),
    format: #cjs,
    exports: #named,
    plugins: [
      Rollup.ReplacePlugin.make({
        values: Dict.fromArray([
          (`S_Core.bs.mjs`, `../src/S_Core.bs.js`),
          (`rescript/lib/es6`, `rescript/lib/js`),
        ]),
      }),
    ],
  },
  {
    file: NodeJs.Path.join2(artifactsPath, "dist/S.mjs"),
    format: #es,
    exports: #named,
    plugins: [
      Rollup.ReplacePlugin.make({
        values: Dict.fromArray([(`S_Core.bs.mjs`, `../src/S_Core.bs.mjs`)]),
      }),
    ],
  },
]
for idx in 0 to output->Array.length - 1 {
  let outpuOptions = output->Array.getUnsafe(idx)
  let _ = await bundle->Rollup.Bundle.write(outpuOptions)
}
await bundle->Rollup.Bundle.close

// Clean up rescript artifacts so the compiled .bs.js files aren't removed on the .bs.mjs build
FsX.rmSync(NodeJs.Path.join2(artifactsPath, "lib"), {force: true, recursive: true})
updateJsonFile(
  ~src=NodeJs.Path.join2(artifactsPath, "rescript.json"),
  ~path=["package-specs", "module"],
  ~value=JSON.Encode.string("commonjs"),
)
updateJsonFile(
  ~src=NodeJs.Path.join2(artifactsPath, "rescript.json"),
  ~path=["suffix"],
  ~value=JSON.Encode.string(".bs.js"),
)
let _ = Execa.sync("npm", ["run", "res:build"], ~options={cwd: artifactsPath}, ())

updateJsonFile(
  ~src=NodeJs.Path.join2(artifactsPath, "package.json"),
  ~path=["type"],
  ~value=JSON.Encode.string("commonjs"),
)

// Clean up before uploading artifacts
FsX.rmSync(NodeJs.Path.join2(artifactsPath, "lib"), {force: true, recursive: true})
FsX.rmSync(NodeJs.Path.join2(artifactsPath, "node_modules"), {force: true, recursive: true})
