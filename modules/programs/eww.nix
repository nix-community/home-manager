{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.eww;

in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.eww = {
    enable = mkEnableOption "eww";

    package = mkOption {
      type = types.package;
      default = pkgs.eww;
      defaultText = literalExpression "pkgs.eww";
      example = literalExpression "pkgs.eww";
      description = ''
        The eww package to install.
      '';
    };

    configDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression "./eww-config-dir";
      description = ''
        The directory that gets symlinked to
        {file}`$XDG_CONFIG_HOME/eww`.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }

    (mkIf (cfg.configDir != null) {
      xdg.configFile."eww".source = cfg.configDir;
    })
  ]);
}
