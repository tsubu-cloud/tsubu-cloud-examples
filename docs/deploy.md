# デプロイ

ビルドした component wasm を OCI レジストリに push する手順です。

## ビルド

```sh
nix build
```

component wasm の作成手順は [README.md](../README.md) を参照してください。
以下では `_build/wasm/debug/build/gen/gen.wasm` から作成した
`/tmp/component.wasm` を push する例を示します。

## レジストリへの push

[oras](https://oras.land/) を使って OCI レジストリに push します。

oras は絶対パス指定を拒否するため、push するファイルのディレクトリに `cd` してから
相対パスで実行します。

```sh
cd /tmp
DIGEST=$(sha256sum component.wasm | cut -d' ' -f1)

oras push ghcr.io/<org>/mbt-http:sha256-${DIGEST} \
  --artifact-type application/vnd.wasm.content.layer.v1+wasm \
  component.wasm:application/wasm
```

- `ghcr.io/<org>/mbt-http:sha256-${DIGEST}` — push 先のリポジトリ・タグ。
  タグは component wasm の内容の sha256 digest を `sha256-` プレフィックス付きで使う
- `--artifact-type` — wasm アーティファクトであることを示す OCI artifact type
- `component.wasm:application/wasm` — push するファイルとその media type

認証には Personal Access Token（`read:packages` / `write:packages` スコープ）または
GitHub Actions 内であれば `GITHUB_TOKEN` が利用できます。

```sh
echo $GITHUB_TOKEN | oras login ghcr.io -u <username> --password-stdin
```
