{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.eclipse;

in

{
  options = {
    programs.eclipse = {
      enable = mkEnableOption "Eclipse";

      jvmArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "JVM arguments to use for the Eclipse process.";
      };

      plugins = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Plugins that should be added to Eclipse.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.eclipses.eclipseWithPlugins {
        eclipse = pkgs.eclipses.eclipse-platform;
        jvmArgs = cfg.jvmArgs;
        plugins = cfg.plugins;
      })
    ];
  };
}
