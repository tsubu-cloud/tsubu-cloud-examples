#!/usr/bin/env bash
# ビルドした component wasm を OCI レジストリに push する。
# 手順の詳細は docs/deploy.md を参照。
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/deploy.sh <component.wasm> <repository>

  <component.wasm>  push する component wasm ファイルのパス
  <repository>       push 先のリポジトリ (例: ghcr.io/<org>/mbt-http)

Environment:
  GITHUB_TOKEN  指定すると oras login を行う (write:packages スコープの PAT、
                または GitHub Actions 内の GITHUB_TOKEN)
  GITHUB_ACTOR  GITHUB_TOKEN 指定時の oras login ユーザー名

Example:
  scripts/deploy.sh /tmp/component.wasm ghcr.io/<org>/mbt-http
EOF
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

wasm_path=$1
repository=$2

if [ ! -f "$wasm_path" ]; then
  echo "error: file not found: $wasm_path" >&2
  exit 1
fi

wasm_dir=$(dirname "$wasm_path")
wasm_file=$(basename "$wasm_path")

digest=$(sha256sum "$wasm_path" | cut -d' ' -f1 | cut -c1-12)
tag="sha256-${digest}"

if [ -n "${GITHUB_TOKEN:-}" ]; then
  : "${GITHUB_ACTOR:?GITHUB_TOKEN を指定する場合は GITHUB_ACTOR も指定してください}"
  echo "$GITHUB_TOKEN" | oras login ghcr.io -u "$GITHUB_ACTOR" --password-stdin
fi

# oras は絶対パス指定を拒否するため、push するファイルのディレクトリに cd してから
# 相対パスで実行する
(
  cd "$wasm_dir"
  oras push "${repository}:${tag}" \
    --artifact-type application/vnd.wasm.content.layer.v1+wasm \
    "${wasm_file}:application/wasm"
)

echo "pushed: ${repository}:${tag}"
