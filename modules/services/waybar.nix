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
      enable = mkEnableOption ''
        Highly customizable Wayland bar for Sway and Wlroots based compositors
      '';

      layer = mkOption {
        default = "bottom";
        type = types.nullOr (types.enum [ "top" "bottom" ]);
        description = ''
          Decide if the bar is dsplayed in front (top) of the windows or behind
          (bottom).
        '';
      };

      output = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Specifies on which screen this bar will be displayed.
        '';
      };

      position = mkOption {
        default = "top";
        type = types.nullOr (types.enum [ "top" "bottom" "left" "right" ]);
        description = ''
          Bar position, can be top, bottom, left, right.
        '';
      };

      height = mkOption {
        default = null;
        type = types.nullOr types.int;
        description = ''
          Height to be used by the bar if possible. Leave blank for a dynamic
          value.
        '';
      };

      width = mkOption {
        default = null;
        type = types.nullOr types.int;
        description = ''
          Width to be used by the bar if possible. Leave blank for dynamic
          value.
        '';
      };

      modules-left = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Modules that will be displayed on the left (as array).
        '';
      };

      modules-center = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Modules that will be displayed in the center (as array).
        '';
      };

      modules-right = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Modules that will be displayed on the right (as array).
        '';
      };

      margin = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Margins value using the CSS format without units.
        '';
      };

      margin-top = mkOption {
        default = null;
        type = types.nullOr types.int;
        description = ''
          Margins value without units.
        '';
      };

      margin-left = mkOption {
        default = null;
        type = types.nullOr types.int;
        description = ''
          Margins value without units.
        '';
      };

      margin-bottom = mkOption {
        default = null;
        type = types.nullOr types.int;
        description = ''
          Margins value without units.
        '';
      };

      margin-right = mkOption {
        default = null;
        type = types.nullOr types.int;
        description = ''
          Margins value without units.
        '';
      };

      name = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          Optional name added as a CSS class, for styling multiple waybars.
        '';
      };

      gtk-layer-shell = mkOption {
        default = true;
        type = types.nullOr types.bool;
        description = ''
          Option to disable the use of gtk-layer-shell for popups.
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
