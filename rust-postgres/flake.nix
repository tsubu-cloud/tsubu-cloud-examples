{
  description = "A startup basic Rust project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      perSystem = { inputs', system, pkgs, ... }:
        let
          rustToolchain = pkgs.rust-bin.stable.latest.default.override {
            targets = [ "wasm32-wasip2" ];
          };

          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.rust-overlay.overlays.default ];
          };

          packages.default = rustPlatform.buildRustPackage {
            pname = "rust-postgres";
            version = "0.0.0";

            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
              outputHashes = {
                "tsubu-router-0.1.0" = "sha256-VtNaxa/QQlZz11v2UdnE+9TiatR+8EJiiTelDhAaZd4=";
              };
            };

            buildPhase = ''
              runHook preBuild
              cargo build --release --target wasm32-wasip2 --offline
              runHook postBuild
            '';

            # ゲストコンポーネントはホスト側のインポートに依存するため単体テストは実行できない
            doCheck = false;

            nativeBuildInputs = [ pkgs.wasm-tools ];

            installPhase = ''
              runHook preInstall
              mkdir -p $out
              cp target/wasm32-wasip2/release/rust_postgres.wasm $out/component.wasm
              cp tsubu.json $out/tsubu.json
              runHook postInstall
            '';
          };
        };

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    };
}
