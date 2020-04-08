{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.waybar;

  configText = builtins.toJSON ({ inherit (cfg) order; } // cfg.extraConfig);

  configFile = pkgs.writeText "config" configText;

in {
  meta.maintainers = [ maintainers.onny ];

  options = {
    services.waybar = {
      enable = mkEnableOption "Waybar";

      settings = mkOption {
        type = format.type;
        default = { };
        description = ''
          Configuration for Waybar, see
          <link xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/>
          for supported values.
        '';
      };

      modules = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Json formatted set of available or custom modules.
        '';
        example = ''
          "sway/window": {
            "max-length": 50
          },
          "battery": {
            "format": "{capacity}% {icon}",
            "format-icons": ["", "", "", "", ""]
          },
          "clock": {
            "format-alt": "{:%a, %d. %b  %H:%M}"
          }
        '';
      };

    };
  };
}
