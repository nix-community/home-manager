{
  config,
  lib,
  pkgs,
  superPkgs,
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

  modulesPkgs = if cfg.config == { } && cfg.overlays == [ ] then
    superPkgs
  else
    import superPkgs.path {
      localSystem = superPkgs.buildPlatform;
      crossSystem = superPkgs.hostPlatform;
      config = mergeConfig superPkgs.config cfg.config;
      overlays = superPkgs.overlays ++ cfg.overlays;
    };

in {
  meta.maintainers = with lib.maintainers; [ thiagokokada ];

  options.nixpkgs = {
    config = lib.mkOption {
      default = { };
      example = { allowBroken = true; };
      type = lib.types.nullOr configType;
      description = ''
        The configuration of the Nix Packages collection. (For
        details, see the Nixpkgs documentation.) It allows you to set
        package configuration options.

        </para><para>

        Note, this option will not apply outside your Home Manager
        configuration like when installing manually through
        <command>nix-env</command>. If you want to apply it both
        inside and outside Home Manager you can put it in a separate
        file and include something like

        <programlisting language="nix">
          nixpkgs.config = import ./nixpkgs-config.nix;
          xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;
        </programlisting>

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
        an argument the <emphasis>original</emphasis> Nixpkgs. The
        first argument should be used for finding dependencies, and
        the second should be used for overriding recipes.

        </para><para>

        Like <varname>nixpkgs.config</varname> this option only
        applies within the Home Manager configuration. See
        <varname>nixpkgs.config</varname> for a suggested setup that
        works both internally and externally.
      '';
    };
  };

  config._module.args.pkgs = lib.mkDefault modulesPkgs;
}
