{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.haskell;
in {
  options.programs.haskell = {
    ghcVersionName = mkOption {
      type = with types; nullOr str;
      apply = opt:
        if opt != null then replaceStrings [ "." ] [ "" ] opt else null;
      description = ''
        The GHC version to use.
        Setting this value automatically sets <code>programs.haskell.haskellPackages</code>.
        The value is automatically stripped of periods to match the nixpkgs naming convention.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''"942"'';
    };
    haskellPackages = mkOption {
      type = types.raw;
      description = "The Haskell package set to use.";
      default = if cfg.ghcVersionName != null then
        pkgs.haskell.packages."ghc${cfg.ghcVersionName}"
      else
        pkgs.haskellPackages;
      defaultText = literalExpression "pkgs.haskellPackages";
      example = literalExpression "pkgs.haskell.packages.ghc923";
    };
  };
  meta.maintainers = with maintainers; [ anselmschueler ];
}
