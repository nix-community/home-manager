{ lib, pkgs, ... }:
let
  # nixpkgs-disabled.nix only loads under `useGlobalPkgs` (useNixpkgsModule =
  # false), which the standard harness can't toggle; evaluate it standalone.
  eval = lib.evalModules {
    modules = [
      ../../../../modules/misc/nixpkgs-disabled.nix
      (pkgs.path + "/nixos/modules/misc/assertions.nix")
      (pkgs.path + "/nixos/modules/misc/meta.nix")
      { _module.args.pkgs = pkgs; }
      ./offending-overlay.nix
    ];
  };

  files = lib.showFiles eval.options.nixpkgs.overlays.files;
in
{
  nmt.script =
    let
      expected = pkgs.writeText "nixpkgs-disabled-warning.expected" ''
        You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`.
        This will soon not be possible. Please remove all `nixpkgs` options when using `home-manager.useGlobalPkgs`.
        Definitions found in ${files}.
      '';

      actual = pkgs.writeText "nixpkgs-disabled-warning.actual" (
        lib.concatStringsSep "\n--\n" eval.config.warnings
      );
    in
    ''
      assertFileContent ${actual} ${expected}
    '';
}
