{ lib, pkgs, ... }:
let
  # The standard harness cannot disable its nixpkgs module, so evaluate the
  # useGlobalPkgs replacement in isolation.
  evaluate =
    definitions:
    lib.evalModules {
      modules = [
        ../../../../modules/misc/nixpkgs-disabled.nix
        (pkgs.path + "/nixos/modules/misc/assertions.nix")
        (pkgs.path + "/nixos/modules/misc/meta.nix")
        { _module.args.pkgs = pkgs; }
      ]
      ++ definitions;
    };

  eval = evaluate [
    ./offending-overlay.nix
    ./offending-config.nix
  ];
  configOnly = evaluate [ ./offending-config.nix ];
  overlayOnly = evaluate [ ./offending-overlay.nix ];
  unset = evaluate [ ];

  files = lib.showFiles (
    lib.unique (eval.options.nixpkgs.config.files ++ eval.options.nixpkgs.overlays.files)
  );

  failed = map (a: a.message) (lib.filter (a: !a.assertion) eval.config.assertions);
in
{
  assertions = [
    {
      assertion = lib.all (a: a.assertion) unset.config.assertions;
      message = "Unset nixpkgs options must be allowed with useGlobalPkgs.";
    }
    {
      assertion =
        lib.any (a: !a.assertion) configOnly.config.assertions
        && lib.any (a: !a.assertion) overlayOnly.config.assertions;
      message = "Either nixpkgs.config or nixpkgs.overlays alone must fail with useGlobalPkgs.";
    }
    {
      assertion = lib.all (result: result.config.warnings == [ ]) [
        eval
        configOnly
        overlayOnly
        unset
      ];
      message = "The useGlobalPkgs assertion must not also emit a deprecation warning.";
    }
  ];

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
