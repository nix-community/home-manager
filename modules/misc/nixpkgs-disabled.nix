{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nixpkgs;

  # Copied from nixpkgs.nix.
  isConfig = x: builtins.isAttrs x || builtins.isFunction x;

  # Copied from nixpkgs.nix.
  optCall = f: x: if builtins.isFunction f then f x else f;

  # Copied from nixpkgs.nix.
  mergeConfig = lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in lhs // rhs // optionalAttrs (lhs ? packageOverrides) {
      packageOverrides = pkgs:
        optCall lhs.packageOverrides pkgs
        // optCall (attrByPath [ "packageOverrides" ] ({ }) rhs) pkgs;
    } // optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides = pkgs:
        optCall lhs.perlPackageOverrides pkgs
        // optCall (attrByPath [ "perlPackageOverrides" ] ({ }) rhs) pkgs;
    };

  # Copied from nixpkgs.nix.
  configType = mkOptionType {
    name = "nixpkgs-config";
    description = "nixpkgs config";
    check = x:
      let traceXIfNot = c: if c x then true else lib.traceSeqN 1 x false;
      in traceXIfNot isConfig;
    merge = args: fold (def: mergeConfig def.value) { };
  };

  # Copied from nixpkgs.nix.
  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = builtins.isFunction;
    merge = lib.mergeOneOption;
  };

in {
  meta.maintainers = with maintainers; [ thiagokokada ];

  options.nixpkgs = {
    config = mkOption {
      default = null;
      type = types.nullOr configType;
      visible = false;
    };

    overlays = mkOption {
      default = null;
      type = types.nullOr (types.listOf overlayType);
      visible = false;
    };
  };

  config = {
    assertions = [{
      assertion = cfg.config == null || cfg.overlays == null;
      message = ''
        `nixpkgs` options are disabled when `home-manager.useGlobalPkgs` is enabled.
      '';
    }];
  };
}
