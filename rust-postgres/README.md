# rust-postgres

Rust で書かれた、tsubu-cloud のホストが提供する `query` / `log` をインポートする
ゲストコンポーネントの example です。`handler` エクスポート内で `users` テーブルを
`query` して全件取得し、JSON で返します。

## 構成

- `wit/guest.wit` — ゲストが import/export する WIT インターフェース定義
- `wit/deps/` — `tsubu_cloud_local wit tsubu.json` が生成する依存 WIT パッケージ
- `src/guest.rs` — `wit-bindgen` が生成したバインディング(DO NOT EDIT)
- `src/lib.rs` — `handler` の実装本体
- `migrations/` — `dbmate` 管理のマイグレーション
- `db/schema.sql` — `dbmate` が生成するスキーマダンプ
- `tsubu.json` — ホストの設定(`DATABASE_URL` など)

## WIT を変更したときのバインディング再生成

```sh
cd examples/rust-postgres
tsubu_cloud_local wit tsubu.json
wit-bindgen rust wit --out-dir src --generate-all
```

`src/guest.rs` は上書きされるので、`src/lib.rs` 側の `use guest::{Guest, Request, Response}`
や `guest::export!(Handler with_types_in guest)` の呼び出しはそのまま動作します。
ただし `postgres` 関連の型は wit_gen が `interface types` を分離したため
`crate::guest::tsubu_cloud::postgres::postgres::DbValue` から
`crate::guest::tsubu_cloud::postgres::types::DbValue` に移動している点に注意してください
(`ParameterValue` も同様)。

## DB のセットアップ

Postgres をコンテナで起動します(`tsubu.json` の `DATABASE_URL` に合わせて
`postgres` データベース、ユーザー/パスワードとも `postgres` を使用):

```sh
docker run -d --name rust-postgres-db \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 postgres:16-alpine
```

マイグレーションを適用します:

```sh
export DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable"
dbmate --migrations-dir migrations up
```

新しいマイグレーションを追加する場合:

```sh
dbmate --migrations-dir migrations new <name>
```

## ビルド

ゲストを `wasm32-wasip2` ターゲット向けにビルドします。このターゲットでは
cargo が直接コンポーネント形式の wasm を出力します(別途 `wasm-tools component
new` などの変換は不要):

```sh
cd examples/rust-postgres
cargo build --release --target wasm32-wasip2
```

`target/wasm32-wasip2/release/rust_postgres.wasm` が生成されます。次のコマンドで
コンポーネントであることを確認できます:

```sh
wasm-tools component wit target/wasm32-wasip2/release/rust_postgres.wasm
```

## CLI のビルド

[tsubu-cloud-cli](https://github.com/tsubu-cloud/tsubu-cloud-cli) を Nix でビルドします
(`zig build` はシステムに `libwasmtime` / `libpq` が無いと失敗するため、Nix
経由が確実です):

```sh
cd /path/to/tsubu-cloud-cli
nix build
export PATH="$PWD/result/bin:$PATH"
```

## 実行

```sh
tsubu_cloud_local \
  examples/rust-postgres/target/wasm32-wasip2/release/rust_postgres.wasm \
  examples/rust-postgres/tsubu.json
```

別のターミナルから:

```sh
curl http://localhost:8080/
```

`users` テーブルの全件が `[{"id":...,"email":...,"created_at":...}, ...]` という
JSON で返ります。
