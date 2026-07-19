{
  description = "A startup basic MoonBit project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    moonbit-overlay.url = "github:moonbit-community/moonbit-overlay";
    moon-registry = {
      url = "git+https://mooncakes.io/git/index";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      perSystem = { inputs', system, pkgs, ... }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [ inputs.moonbit-overlay.overlays.default ];
        };

        packages.default = pkgs.moonPlatform.buildMoonPackage {
          src = ./.;
          moonModJson = ./moon.mod.json;
          moonRegistryIndex = inputs.moon-registry;

          nativeBuildInputs = [ pkgs.wasm-tools ];

          # ゲストコンポーネントはホスト側のインポートに依存するため単体テストは実行できない
          doCheck = false;

          installPhase = ''
            mkdir -p $out
            wasm-tools component embed wit $TMP/_build/wasm/release/build/gen/gen.wasm \
              -o $TMP/embedded.wasm --world guest --encoding utf16
            wasm-tools component new $TMP/embedded.wasm -o $out/component.wasm
            cp $TMP/tsubu.json $out/tsubu.json
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
