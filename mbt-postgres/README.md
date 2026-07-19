# mbt-postgres

MoonBit で書かれた、tsubu-cloud のホストが提供する `query` / `log` を
インポートするゲストコンポーネントの example です。`handler` エクスポート内で
`query` を呼び出し、結果を `log` で出力します。

## 構成

- `wit/guest.wit` — ゲストが import/export する WIT インターフェース定義
- `wit/deps/` — `tsubu_cloud_local wit tsubu.json` が生成する依存 WIT パッケージ
- `world/guest/` — `wit-bindgen` が生成した import 側バインディング(`query`, `log`)
- `gen/` — `wit-bindgen` が生成したエントリポイント。`gen/world/guest/handler.mbt` に
  `handler` の実装(`world/guest` の `query`/`log` を呼び出す本体)を置いている

## WIT を変更したときのバインディング再生成

```sh
cd examples/mbt-postgres
tsubu_cloud_local wit tsubu.json
wit-bindgen moonbit wit --ignore-module-file --out-dir . --project-name tsubu/mbt-postgres
```

`--project-name tsubu/mbt-postgres` は `moon.mod.json` の `name` と一致させることで、
生成される `import` パスのプレフィックスを `tsubu/mbt-postgres/...` に揃えるために必要です。

`gen/` 以下のファイルは基本的に上書きされるので、`gen/world/guest/handler.mbt` と
`gen/world/guest/moon.pkg.json` の `import` 設定
(`tsubu/mbt-postgres/interface/tsubu_cloud/logger/logger` を `logger`、
`tsubu/mbt-postgres/interface/tsubu_cloud/postgres/postgres` を `postgres`、
`tsubu/mbt-postgres/interface/tsubu_cloud/handler/types` を `types` としてインポート)
は再生成後に必要であれば復元してください。

## ビルド

```sh
cd examples/mbt-postgres
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

リポジトリルートで:

```sh
cargo run --release -- /tmp/component.wasm
```

クエリ結果の行数が標準出力にログ出力されます。
