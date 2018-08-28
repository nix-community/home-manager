{ pkgs, lib }:

with lib;

let

  monitor = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The name or id of the monitor (MONITOR_SEL).";
        example = "HDMI-0";
      };

      desktops = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The desktops that the monitor is going to hold";
        example = [ "web" "terminal" "III" "IV" ];
      };
    };
  };

  rule = types.submodule {
    options = {
      className = mkOption {
        type = types.str;
        default = "";
        description = "The class name of the program you want to apply the rule";
        example = "Firefox";
      };

      instanceName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The particular instance name of a program";
        example = "Navigator";
      };

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

      # AAHFUIOEHFUIWEHFWUIEHFUIWEH
      node = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The node where the rule should be applied";
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

      # splitRatio = mkOption {
      #   type = types.nullOr types.float;
      #   default = null;
      #   description = "The ratio between the new window and the previous existing window in the desktop";
      #   example = 0.65;
      # };

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

      # AIOFGHIEUWHGWUIEHGUIWEGHUIWE
      center = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "";
        example = true;
      };

      follow = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the previous focused node is going to stay focused";
        example = true;
      };

      # GVWIOERHGIOWERHGOWIERGHWIOEHGWIOEHGIOWERHGWO
      manage = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "";
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
        bspc rule -a Gimp desktop='^8' state=floating follow=on
        bspc rule -a Chromium desktop='^2'
        bspc rule -a mplayer2 state=floating
        bspc rule -a Kupfer.py focus=on
        bspc rule -a Screenkey manage=off
      '';
    };

    monitors = mkOption {
      type = types.listOf monitor;
      default = [];
      description = "bspc monitor configurations";
      example = ''
        [
          {
            name = "HDMI-0";
            desktops = [ "web" "terminal" "III" "IV" ];
          }
        ];
      '';
    };

    rules = mkOption {
      type = types.listOf rule;
      default = [];
      description = "bspc rules";
      example = ''
        [
          {
            className = "Gimp";
            desktop = "^8";
            state = "floating";
            follow = true;
          }
          {
            className = "Chromium";
            desktop = "^2";
          }
          {
            className = "mplayer2";
            state = "floating";
          }
          {
            className = "Kupfer.py";
            focus = true;
          }
          {
            className = "Screenkey";
            manage = false;
          }
        ];
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
