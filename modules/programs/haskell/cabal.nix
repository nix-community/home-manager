{ config, pkgs, lib, ... }:
with builtins // lib;
let cfg = config.programs.haskell.cabal;
in {
  options.programs.haskell.cabal = {
    enable = mkEnableOption "the Haskell Cabal (build system)";
    package = mkPackageOption pkgs "Cabal" { default = [ "cabal-install" ]; };
    config = mkOption {
      type = with types; nullOr lines;
      description = ''
        The contents of the <code>.cabal/config</code> file.
        If set to <code>null</code>, no file will be generated.
      '';
      default = null;
      defaultText = literalExpression "null";
      example = literalExpression ''
        '''
          executable-stripping: True
        '''
      '';
    };
  };
  config.home = mkIf cfg.enable {
    packages = [ cfg.package ];
    file.".cabal/config" = mkIf (cfg.config != null) { text = cfg.config; };
  };
}
