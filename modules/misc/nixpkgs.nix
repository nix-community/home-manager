# Adapted from Nixpkgs.

{
  config,
  lib,
  pkgs,
  pkgsPath,
  superPkgs,
  ...
}:

let

  cfg = config.nixpkgs;

  isConfig = x: builtins.isAttrs x || builtins.isFunction x;

  optCall = f: x: if builtins.isFunction f then f x else f;

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

  overlayType = lib.mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };

  _pkgs = if cfg.inheritGlobalPkgs then
    if cfg.config == { } && cfg.overlays == [ ] && cfg.system == null then
      superPkgs
    else
      import superPkgs.path {
        localSystem = superPkgs.stdenv.buildPlatform;
        crossSystem = if cfg.system == null then
          superPkgs.stdenv.hostPlatform
        else
          cfg.system;
        config = mergeConfig superPkgs.config cfg.config;
        overlays = superPkgs.overlays ++ cfg.overlays;
      }
  else
    import pkgsPath (lib.filterAttrs (n: v: v != null) cfg);

in
{
  options.nixpkgs = {
    inheritGlobalPkgs = lib.mkOption {
      defaultText = lib.literalExpression "usingNixosModule && useGlobalPkgs";
      example = false;
      type = lib.types.bool;
      description = ''
        Whether to build the configuration with the Nixpkgs passed to
        Home Manager instead of re-importing it fresh.
      '';
    };

    config = lib.mkOption {
      default = { };
      example = {
        allowBroken = true;
      };
      type = lib.types.nullOr configType;
      description = ''
        The configuration of the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to set
        package configuration options.

        If `null` and {option}`nixpkgs.inheritGlobalPkgs` is `false`,
        then configuration is taken from the fallback location, for
        example, {file}`~/.config/nixpkgs/config.nix`.

        Note, this option will not apply outside your Home Manager
        configuration like when installing manually through
        {command}`nix-env`. If you want to apply it both
        inside and outside Home Manager you can put it in a separate
        file and include something like

        ```nix
          nixpkgs.config = import ./nixpkgs-config.nix;
          xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
        ```

        in your Home Manager configuration.
      '';
    };

    overlays = lib.mkOption {
      default = [ ];
      example = lib.literalExpression ''
        [
          (final: prev: {
            openssh = prev.openssh.override {
              hpnSupport = true;
              withKerberos = true;
              kerberos = final.libkrb5;
            };
          })
        ]
      '';
      type = lib.types.nullOr (lib.types.listOf overlayType);
      description = ''
        List of overlays to use with the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to
        override packages globally. This is a function that takes as
        an argument the *original* Nixpkgs. The
        first argument should be used for finding dependencies, and
        the second should be used for overriding recipes.

        If `null` and {option}`nixpkgs.inheritGlobalPkgs` is `false`,
        then the overlays are taken from the fallback location, for
        example, {file}`~/.config/nixpkgs/overlays`.

        Like {var}`nixpkgs.config` this option only
        applies within the Home Manager configuration. See
        {var}`nixpkgs.config` for a suggested setup that
        works both internally and externally.
      '';
    };

    system = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      example = "i686-linux";
      internal = true;
      description = ''
        Specifies the Nix platform type for which the user environment
        should be built. If unset, it defaults to the platform type of
        your host system. Specifying this option is useful when doing
        distributed multi-platform deployment, or when building
        virtual machines.
      '';
    };
  };

  config = {
    _module.args = {

      # An override is also necessary here to make sure that the option
      # can be merged without evaluating `_pkgs`, see
      # https://github.com/nix-community/home-manager/pull/993
      pkgs = lib.mkDefault _pkgs;
      pkgs_i686 =
        if _pkgs.stdenv.isLinux && _pkgs.stdenv.hostPlatform.isx86 then _pkgs.pkgsi686Linux else { };
    };
  };
}
