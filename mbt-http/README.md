# mbt-http

MoonBit で書かれた、tsubu-cloud のホストが提供する `tsubu-cloud:fetcher/fetcher` /
`tsubu-cloud:logger/logger` をインポートするゲストコンポーネントの example です。
`handler` エクスポート内で `https://example.com` を取得し、レスポンスボディを
`log` で出力します。

## 構成

- `wit/guest.wit` — ゲストが import/export する WIT インターフェース定義
- `interface/` — `wit-bindgen` が生成した import 側バインディング(`fetcher`, `logger`)
- `gen/` — `wit-bindgen` が生成したエントリポイント。`gen/world/guest/handler.mbt` に
  `handler` の実装(`fetcher`/`logger` を呼び出す本体)を置いている
- `tsubu.json` — ホスト側で `fetch` / `log` 配列の PACKAGE・ALIAS・TARGET を
  設定する(PACKAGE が import 先の WIT インターフェース名、ALIAS がその中の
  関数名に対応する)

## WIT を変更したときのバインディング再生成

```sh
cd examples/mbt-http
wit-bindgen moonbit wit --ignore-module-file --out-dir . --project-name tsubu/mbt-http
```

`--project-name tsubu/mbt-http` は `moon.mod.json` の `name` と一致させることで、
生成される `import` パスのプレフィックスを `tsubu/mbt-http/...` に揃えるために必要です。

`gen/` 以下のファイルは基本的に上書きされるので、`gen/world/guest/handler.mbt` と
`gen/world/guest/moon.pkg.json` の `import` 設定
(`tsubu/mbt-http/interface/tsubu_cloud/fetcher/fetcher` を `fetcher`、
`tsubu/mbt-http/interface/tsubu_cloud/fetcher/types` を `fetcher_types`、
`tsubu/mbt-http/interface/tsubu_cloud/logger/logger` を `logger`、
`tsubu/mbt-http/interface/tsubu_cloud/handler/types` を `types` としてインポート)
は再生成後に必要であれば復元してください。

## ビルド

```sh
cd examples/mbt-http
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

`tsubu.json` (`fetch` / `log` 設定)がある `examples/mbt-http` をカレント
ディレクトリにして、wasm モジュールと設定ファイルのパスを指定して実行します:

```sh
cd examples/mbt-http
tsubu_cloud_local /tmp/component.wasm tsubu.json
```

`example.com` から取得した HTML が標準出力にログ出力されます。
