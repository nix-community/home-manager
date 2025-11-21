{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.nixpkgs;

  # Copied from nixpkgs.nix.
  isConfig = x: builtins.isAttrs x || builtins.isFunction x;

  # Copied from nixpkgs.nix.
  optCall = f: x: if builtins.isFunction f then f x else f;

  # Copied from nixpkgs.nix.
  mergeConfig =
    lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in
    lhs
    // rhs
    // lib.optionalAttrs (lhs ? packageOverrides) {
      packageOverrides =
        pkgs:
        optCall lhs.packageOverrides pkgs // optCall (lib.attrByPath [ "packageOverrides" ] { } rhs) pkgs;
    }
    // lib.optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides =
        pkgs:
        optCall lhs.perlPackageOverrides pkgs
        // optCall (lib.attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
    };

  # Copied from nixpkgs.nix.
  configType = lib.mkOptionType {
    name = "nixpkgs-config";
    description = "nixpkgs config";
    check =
      x:
      let
        traceXIfNot = c: if c x then true else lib.traceSeqN 1 x false;
      in
      traceXIfNot isConfig;
    merge = args: lib.fold (def: mergeConfig def.value) { };
  };

  # Copied from nixpkgs.nix.
  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = builtins.isFunction;
    merge = lib.mergeOneOption;
  };

in
{
  meta.maintainers = with lib.maintainers; [ thiagokokada ];

  options.nixpkgs = {
    config = lib.mkOption {
      default = null;
      type = lib.types.nullOr configType;
      visible = false;
    };

    overlays = lib.mkOption {
      default = null;
      type = lib.types.nullOr (lib.types.listOf overlayType);
      visible = false;
    };
  };

  config = {
    assertions = [
      # TODO: Re-enable assertion after 25.05 (&&)
      {
        assertion = cfg.config == null || cfg.overlays == null;
        message = ''
          `nixpkgs` options are disabled when `home-manager.useGlobalPkgs` is enabled.
        '';
      }
    ];

    warnings = lib.optional ((cfg.config != null) || (cfg.overlays != null)) ''
      You have set either `nixpkgs.config` or `nixpkgs.overlays` while using `home-manager.useGlobalPkgs`.
      This will soon not be possible. Please remove all `nixpkgs` options when using `home-manager.useGlobalPkgs`.
    '';
  };
}
