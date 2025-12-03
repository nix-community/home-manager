{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.calibre;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.calibre = {
    enable = mkEnableOption "calibre";
    package = mkPackageOption pkgs "calibre" { nullable = true; };
    plugins = mkOption {
      type = with types; listOf path;
      default = [ ];
      description = "List of plugins to install for calibre";
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = mkIf (cfg.plugins != [ ]) (
      let
        symlinkedPlugins = pkgs.symlinkJoin {
          name = "calibre-plugins";
          paths = cfg.plugins;
        };
      in
      lib.mapAttrs' (
        k: _: lib.nameValuePair "calibre/plugins/${k}" { source = (symlinkedPlugins + "/${k}"); }
      ) (builtins.readDir symlinkedPlugins)
    );
  };
}
