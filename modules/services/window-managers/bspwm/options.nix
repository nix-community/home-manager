{ pkgs, lib }:

with lib;

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
};