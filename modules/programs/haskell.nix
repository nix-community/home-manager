{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.haskell;
in {
  meta.maintainers = with lib.maintainers; [ anselmschueler ];
  options.programs.haskell = {
    haskellPackages = mkOption {
      type = with types; attrsOf package;
      description = "The Haskell package set to use";
      default = pkgs.haskellPackages;
      defaultText = literalExpression "pkgs.haskellPackages";
      example = literalExpression "pkgs.haskell.packages.ghc923";
    };
    ghc = {
      enable = mkEnableOption
        "the Glorious Glasgow Haskell Compilation System (compiler)";
      package = mkPackageOption config.programs.haskell.haskellPackages "GHC" {
        default = [ "ghc" ];
      };
      installedPackages = mkOption {
        type = with types;
          either (functionTo (listOf package)) (listOf package);
        apply = x: if !builtins.isFunction x then _: x else x;
        description = "The Haskell library packages to install for GHC";
        default = hkgs: [ ];
        defaultText = literalExpression "hkgs: [ ]";
        example = literalExpression "hkgs: [ hkgs.primes ]";
      };
      interactiveConfig = mkOption {
        type = with types; nullOr lines;
        description = "The contents of the <code>.ghci</code> file";
        default = null;
        defaultText = literalExpression "null";
        example = literalExpression ''
          :set +m
        '';
      };
    };
    stack = {
      enable = mkEnableOption "the Haskell Tool Stack";
      package = mkPackageOption pkgs "Stack" { default = [ "stack" ]; };
    };
    cabal = {
      enable = mkEnableOption "the Haskell Cabal (build system)";
      package = mkPackageOption pkgs "Cabal" { default = [ "cabal-install" ]; };
    };
  };
  config = {
    home.packages = optional cfg.ghc.enable
      (if cfg.ghc.package ? withPackages then
        cfg.ghc.package.withPackages cfg.ghc.installedPackages
      else
        cfg.ghc.package) ++ optional cfg.stack.enable cfg.stack.package
      ++ optional cfg.cabal.enable cfg.cabal.package;
    xdg.configFile.".ghci" = mkIf (cfg.ghc.interactiveConfig != null) {
      text = cfg.ghc.interactiveConfig;
    };
    warnings = mkIf (!cfg.ghc.package ? withPackages) [''
      You have provided a package as programs.haskell.ghc.package that doesn't have the withPackages utility function.
      This disables specifying packages via programs.haskell.ghc.packages.
    ''];
  };
}
