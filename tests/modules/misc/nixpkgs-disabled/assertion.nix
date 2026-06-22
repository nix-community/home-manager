{ lib, pkgs, ... }:
let
  # Both options set trips the assertion; it should list both locations.
  eval = lib.evalModules {
    modules = [
      ../../../../modules/misc/nixpkgs-disabled.nix
      (pkgs.path + "/nixos/modules/misc/assertions.nix")
      (pkgs.path + "/nixos/modules/misc/meta.nix")
      { _module.args.pkgs = pkgs; }
      ./offending-overlay.nix
      ./offending-config.nix
    ];
  };

  files = lib.showFiles (
    lib.unique (eval.options.nixpkgs.config.files ++ eval.options.nixpkgs.overlays.files)
  );

  failed = map (a: a.message) (lib.filter (a: !a.assertion) eval.config.assertions);
in
{
  nmt.script =
    let
      expected = pkgs.writeText "nixpkgs-disabled-assertion.expected" ''
        `nixpkgs` options are disabled when `home-manager.useGlobalPkgs` is enabled.
        Definitions found in ${files}.
      '';

      actual = pkgs.writeText "nixpkgs-disabled-assertion.actual" (lib.concatStringsSep "\n--\n" failed);
    in
    ''
      assertFileContent ${actual} ${expected}
    '';
}
