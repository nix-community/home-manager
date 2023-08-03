{ config, options, pkgs, lib, pkgsPath, ... }:

with lib;

let
  cfg = config.nixpkgs;
  opt = options.nixpkgs;

  isConfig = x: builtins.isAttrs x || isFunction x;

  optCall = f: x: if isFunction f then f x else f;

  mergeConfig = lhs_: rhs_:
    let
      lhs = optCall lhs_ { inherit pkgs; };
      rhs = optCall rhs_ { inherit pkgs; };
    in recursiveUpdate lhs rhs // optionalAttrs (lhs ? packageOverrides) {
      packageOverrides = pkgs:
        optCall lhs.packageOverrides pkgs
        // optCall (attrByPath [ "packageOverrides" ] { } rhs) pkgs;
    } // optionalAttrs (lhs ? perlPackageOverrides) {
      perlPackageOverrides = pkgs:
        optCall lhs.perlPackageOverrides pkgs
        // optCall (attrByPath [ "perlPackageOverrides" ] { } rhs) pkgs;
    };

  configType = mkOptionType {
    name = "nixpkgs-config";
    description = "nixpkgs config";
    check = x:
      let traceXIfNot = c: if c x then true else traceSeqN 1 x false;
      in traceXIfNot isConfig;
    merge = _: foldr (def: mergeConfig def.value) { };
  };

  overlayType = mkOptionType {
    name = "nixpkgs-overlay";
    description = "nixpkgs overlay";
    check = isFunction;
    merge = mergeOneOption;
  };

  defaultPkgs = import pkgsPath {
    config = if cfg.config != null then cfg.config else { };

    overlays = if cfg.overlays != null then cfg.overlays else [ ];

    #crossSystem = if cfg.system != null then cfg.system else throw "system must be set";
    localSystem =
      if cfg.system != null then cfg.system else throw "system must be set";
  };

  pkgsDefined = opt.pkgs.isDefined;

in {
  options.nixpkgs = {
    pkgs = lib.mkOption {
      defaultText = ''
        import pkgsPath {
          inherit (cfg) config overlays localSystem crossSystem;
        }
      '';
      type = lib.types.pkgs;
      example = "import <nixpkgs> {}";
      description = ''
        If set, the pkgs argument to all NixOS modules is the value of
        this option, extended with `nixpkgs.overlays`, if
        that is also set. Either `nixpkgs.crossSystem` or
        `nixpkgs.localSystem` will be used in an assertion
        to check that the NixOS and Nixpkgs architectures match. Any
        other options in `nixpkgs.*`, notably `config`,
        will be ignored.

        If unset, the pkgs argument to all NixOS modules is determined
        as shown in the default value for this option.

        The default value imports the Nixpkgs source files
        relative to the location of this NixOS module, because
        NixOS and Nixpkgs are distributed together for consistency,
        so the `nixos` in the default value is in fact a
        relative path. The `config`, `overlays`,
        `localSystem`, and `crossSystem` come
        from this option's siblings.

        This option can be used by applications like NixOps to increase
        the performance of evaluation, or to create packages that depend
        on a container that should be built with the exact same evaluation
        of Nixpkgs, for example. Applications like this should set
        their default value using `mkDefault`, so
        user-provided configuration can override it without using
        `.

        Note that using a distinct version of Nixpkgs with NixOS may
        be an unexpected source of problems. Use this option with care.
      '';
    };
    config = mkOption {
      default = null;
      example = { allowBroken = true; };
      type = types.nullOr configType;
      description = ''
        The configuration of the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to set
        package configuration options.

        If `null`, then configuration is taken from
        the fallback location, for example,
        {file}`~/.config/nixpkgs/config.nix`.

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

    overlays = mkOption {
      default = null;
      example = literalExpression ''
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
      type = types.nullOr (types.listOf overlayType);
      description = ''
        List of overlays to use with the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to
        override packages globally. This is a function that takes as
        an argument the *original* Nixpkgs. The
        first argument should be used for finding dependencies, and
        the second should be used for overriding recipes.

        If `null`, then the overlays are taken from
        the fallback location, for example,
        {file}`~/.config/nixpkgs/overlays`.

        Like {var}`nixpkgs.config` this option only
        applies within the Home Manager configuration. See
        {var}`nixpkgs.config` for a suggested setup that
        works both internally and externally.
      '';
    };

    system = mkOption {
      default = if (!lib.inPureEvalMode) then {
        system = builtins.currentSystem;
      } else
        null;
      type = types.nullOr types.str;
      example = "i686-linux";
      description = ''
        Specifies the Nix platform type for which the user environment
        should be built. If unset, it defaults to the platform type of
        your host system. Specifying this option is useful when doing
        distributed multi-platform deployment, or when building
        virtual machines.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (!pkgsDefined) {
      # We explicitly set the default override priority, so that we do not need
      # to evaluate finalPkgs in case an override is placed on `_module.args.pkgs`.
      # After all, to determine a definition priority, we need to evaluate `._type`,
      # which is somewhat costly for Nixpkgs. With an explicit priority, we only
      # evaluate the wrapper to find out that the priority is lower, and then we
      # don't need to evaluate `finalPkgs`.
      _module.args.pkgs =
        mkOverride modules.defaultOverridePriority defaultPkgs.__splicedPackages;
    })

    (lib.mkIf pkgsDefined {
      _module.args.pkgs =
        # find mistaken definitions
        lib.mkForce
        (builtins.seq cfg.config builtins.seq cfg.overlays builtins.seq
          cfg.system (cfg.pkgs.appendOverlays cfg.overlays));
      nixpkgs = {
        config = lib.mkForce cfg.pkgs.config;
        overlays = lib.mkForce cfg.pkgs.overlays;
        system = lib.mkForce cfg.pkgs.hostPlatform.system;
      };

    })
  ];
}
