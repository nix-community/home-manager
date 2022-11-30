{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.haskell.ghc;
in {
  options.programs.haskell.ghc = {
    enable = mkEnableOption
      "the Glorious Glasgow Haskell Compilation System (GHC, the compiler)";
    package = mkPackageOption config.programs.haskell.haskellPackages "GHC" {
      default = [ "ghc" ];
    } // {
      apply = pkg:
        if pkg ? withPackages then
          pkg.withPackages cfg.packages
        else
          trace ''
            You have provided a package as programs.haskell.ghc.package that doesn't have the withPackages function.
            This disables specifying packages via programs.haskell.ghc.packages unless you manually install them.
          '' pkg;
    };
    packages = mkOption {
      type = with types; functionTo (listOf package);
      apply = x: if !isFunction x then _: x else x;
      description = ''
        The Haskell packages to install for GHC.
        This installs the packages for GHC only, not in your actual user profile.
      '';
      default = hkgs: [ ];
      defaultText = literalExpression "hkgs: [ ]";
      example = literalExpression "hkgs: [ hkgs.primes ]";
    };
    ghciConfig = mkOption {
      type = with types; nullOr lines;
      description = ''
        The contents of the <code>.ghci</code> file.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        '''
          :set +s
        '''
      '';
    };
  };
  config.home = mkIf cfg.enable {
    packages = [ cfg.package ];
    file.".ghci" = mkIf (cfg.ghciConfig != null) { text = cfg.ghciConfig; };
  };
}
