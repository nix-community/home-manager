{ pkgs, lib }:

with lib;

let
  rule = types.submodule {
    options = {
      monitor = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The monitor where the rule should be applied";
        example = "HDMI-0";
      };

      desktop = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The desktop where the rule should be applied";
        example = "^8";
      };

      node = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The node where the rule should be applied";
        example = "1";
      };

      state = mkOption {
        type = types.nullOr (types.enum [ "tiled" "pseudo_tiled" "floating" "fullscreen" ]);
        default = null;
        description = "The state in where the window should be spawned";
        example = "floating";
      };

      layer = mkOption {
        type = types.nullOr (types.enum [ "below" "normal" "above" ]);
        default = null;
        description = "The layer where the window should be spawned";
        example = "above";
      };

      splitDir = mkOption {
        type = types.nullOr (types.enum [ "north" "west" "south" "east" ]);
        default = null;
        description = "The direction where the container is going to be splitted";
        example = "south";
      };

      splitRatio = mkOption {
        type = types.nullOr types.float;
        default = null;
        description = "The ratio between the new window and the previous existing window in the desktop";
        example = 0.65;
      };

      hidden = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node isn't going to occupy any space";
        example = true;
      };

      sticky = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to stay in the focused desktop of its monitor";
        example = true;
      };

      private = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to try to stay in the same tiling position and size";
        example = true;
      };

      locked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to ignore the 'node --close' messae";
        example = true;
      };

      marked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to be marked for deferred actions";
        example = true;
      };

      center = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node will be put in the center of the screen in floating mode.";
        example = true;
      };

      follow = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the previous focused node is going to stay focused";
        example = true;
      };

      manage = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If set to false, the window will not be managed by bspwm at all";
        example = true;
      };

      focus = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the new node is going to gain the focus";
        example = true;
      };

      border = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the new node is going to have border";
        example = true;
      };
    };
  };

in

{
  xsession.windowManager.bspwm = {
    enable = mkEnableOption "bspwm window manager.";

    package = mkOption {
        type = types.package;
        default = pkgs.bspwm;
        defaultText = "pkgs.bspwm";
        description = "bspwm package to use.";
        example = "pkgs.bspwm-unstable";
    };

    config = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      description = "bspwm configuration";
      example = {
        "border_width" = 2;
        "split_ratio" = 0.52;
        "gapless_monocle" = true;
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional configuration to add";
      example = ''
        bspc subscribe all > ~/bspc-report.log &
      '';
    };

    applyJavaGuiFixes = mkOption {
      type = types.bool;
      default = true;
      description = "Add _JAVA_AWT_WM_NONREPARENTING to environment, to fix some Java GUI applications.";
      example = true;
    };

    monitors = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = "bspc monitor configurations";
      example = ''
        {
          "HDMI-0" = [ "web" "terminal" "III" "IV" ];
        }
      '';
    };

    rules = mkOption {
      type = types.attrsOf rule;
      default = {};
      description = "bspc rules";
      example = ''
        {
          "Gimp" = {
            desktop = "^8";
            state = "floating";
            follow = true;
          };
          "Chromium" = {
            desktop = "^2";
          }
          "mplayer2" = {
            state = "floating";
          }
          "Kupfer.py" = {
            focus = true;
          }
          "Screenkey" = {
            manage = false;
          }
        };
      '';
    };

    startupPrograms = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Programs that are going to be executed in the startup";
      example = ''
        [
          "numlockx on"
          "tilda"
        ];
      '';
    };
  };
}
