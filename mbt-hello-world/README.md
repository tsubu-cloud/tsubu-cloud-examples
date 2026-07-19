# mbt-hello-world

MoonBit で書かれた、`handler` エクスポート内でただ `"Hello World"` を返すだけの
tsubu-cloud ゲストコンポーネントの example です。ホスト側のインポート
(`fetcher`/`logger` など)には依存しません。

## 構成

- `wit/guest.wit` — ゲストが export する WIT インターフェース定義(ホストが提供する
  `tsubu-cloud:logger/logger` を import する)
- `wit/deps/` — `tsubu_cloud_local wit tsubu.json` が生成する依存 WIT パッケージ
- `gen/` — `wit-bindgen` が生成したエントリポイント。`gen/world/guest/handler.mbt` に
  `handler` の実装(`"Hello World"` を返すだけの本体)を置いている
- `tsubu.json` — ホスト側の設定(このサンプルでは import 先がないため `fetch`/`postgres` とも空配列)

## WIT を変更したときのバインディング再生成

```sh
cd examples/mbt-hello-world
tsubu_cloud_local wit tsubu.json
wit-bindgen moonbit wit --ignore-module-file --out-dir . --project-name tsubu/mbt-hello-world
```

`--project-name tsubu/mbt-hello-world` は `moon.mod.json` の `name` と一致させることで、
生成される `import` パスのプレフィックスを `tsubu/mbt-hello-world/...` に揃えるために必要です。

`gen/` 以下のファイルは基本的に上書きされるので、`gen/world/guest/handler.mbt` は
再生成後に復元してください。

## ビルド

```sh
cd examples/mbt-hello-world
moon build --target wasm
```

`_build/wasm/debug/build/gen/gen.wasm` にコア wasm モジュールが出力されます。

## コンポーネント化

MoonBit の文字列は UTF-16 でエンコードされるため、component 化の際は
`--encoding utf16` を指定する必要があります(省略するとホスト側で文字列が
壊れて渡ります)。

```sh
wasm-tools component embed wit _build/wasm/debug/build/gen/gen.wasm \
  -o /tmp/embedded.wasm --world guest --encoding utf16
wasm-tools component new /tmp/embedded.wasm -o /tmp/component.wasm
```

## 実行

[tsubu-cloud-cli](https://github.com/tsubu-cloud/tsubu-cloud-cli) をビルドし、
`result/bin/tsubu_cloud_local` に PATH を通します:

```sh
cd path/to/tsubu-cloud-cli
nix build
export PATH="$PWD/result/bin:$PATH"
```

`tsubu.json` がある `examples/mbt-hello-world` をカレントディレクトリにして、
wasm モジュールと設定ファイルのパスを指定して実行します:

```sh
cd examples/mbt-hello-world
tsubu_cloud_local run /tmp/component.wasm tsubu.json
```

```sh
curl http://localhost:8080/
# => Hello World
```
