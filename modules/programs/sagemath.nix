{ config, lib, pkgs, ... }:

let

  cfg = config.programs.sagemath;

  inherit (lib) literalExpression mkEnableOption mkOption types;

in {
  meta.maintainers = [ lib.maintainers.kirelagin ];

  options.programs.sagemath = {
    enable = mkEnableOption "SageMath, a mathematics software system";

    package = mkOption {
      type = types.package;
      default = pkgs.sage;
      defaultText = literalExpression "pkgs.sage";
      description = "The SageMath package to use.";
    };

    configDir = mkOption {
      type = types.str;
      default = "${config.xdg.configHome}/sage";
      defaultText = literalExpression "\${config.xdg.configHome}/sage";
      description = ''
        Directory where the <filename>sage.init</filename> file will be stored.
        Note that the upstream default is <filename>~/.sage</filename>,
        but our default is to follow XDG.
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "${config.xdg.dataHome}/sage";
      defaultText = literalExpression "\${config.xdg.dataHome}/sage";
      description = ''
        Location for <envar>DOT_SAGE</envar>.
        Note that the upstream default is <filename>~/.sage</filename>,
        but our default is to follow XDG.
      '';
    };

    initScript = mkOption {
      type = types.lines;
      default = "";
      example = "%colors linux";
      description = ''
        Contents of the <filename>init.sage</filename> file that is loaded on startup.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${cfg.configDir}/init.sage".text = cfg.initScript;
    home.sessionVariables = {
      DOT_SAGE = cfg.dataDir;
      SAGE_STARTUP_FILE = "${cfg.configDir}/init.sage";
    };
  };
}
