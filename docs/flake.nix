{
  description = "Support developing Home Manager documentation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    scss-reset = {
      url = "github:andreymatin/scss-reset/1.4.2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, scss-reset }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      # Note, this should be "the standard library" + HM extensions.
      lib = import ../modules/lib/stdlib-extended.nix nixpkgs.lib;

      forAllSystems = lib.genAttrs supportedSystems;

      flakePkgs = pkgs: {
        p-build = pkgs.writeShellScriptBin "p-build" ''
          set -euo pipefail

          export PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.rsass ]}

          tmpfile=$(mktemp -d)
          trap "rm -r $tmpfile" EXIT

          ln -s "${scss-reset}/build" "$tmpfile/scss-reset"

          rsass --load-path="$tmpfile" --style compressed \
            ./static/style.scss > ./static/style.css
          echo "Generated ./static/style.css"
        '';
      };

      releaseInfo = lib.importJSON ../release.json;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fpkgs = flakePkgs pkgs;
        in {
          default = pkgs.mkShell {
            name = "hm-docs";
            packages = [ fpkgs.p-build ];
          };
        });

      # Expose the docs outputs
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          docs = import ./default.nix {
            inherit pkgs lib;
            release = releaseInfo.release;
            isReleaseBranch = releaseInfo.isReleaseBranch;
          };
        in {
          inherit (docs) manPages jsonModuleMaintainers;
          inherit (docs.manual) html htmlOpenTool;
          inherit (docs.options) json;
        });
    };
}
