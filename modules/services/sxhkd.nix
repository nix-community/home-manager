{ config, lib, pkgs, ... }:

with lib;

let
  hotkey = types.submodule {
    options = {
      comment = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "A small description of the hotkey";
        example = "Move a floating window";
      };
    };
  };

  section = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        default = "";
        description = "The title of the section that the configuration file is going to have";
        example = "Media hotkeys";
      };

      hotkeys = mkOption {
        type = types.listOf hotkey;
        default = {};
        description = "All the hotkeys combinations for the section";
        example = {SOMETHING};
      };
    };
  };

in

{
  options = {
    services.sxhkd = {
      enable = mkEnableOption "sxhkd hotkey daemon";

      package = mkOption {
        type = types.package;
        default = pkgs.sxhkd;
        description = "sxhkd package to install.";
        example = "sxhkd-unstable";
      };
    };

    config = mkOption {
      type = types.listOf section;
      description = "sxhkd configuration.";
      default = {};
      example = {
        SOMETHING!
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additonal configuration to add.";
      example = ''
        #
        # move/resize
        #

        # expand a window by moving one of its side outward
        super + alt + {h,j,k,l}
          bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}

        # contract a window by moving one of its side inward
        super + alt + shift + {h,j,k,l}
          bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}

        # move a floating window
        super + {Left,Down,Up,Right}
          bspc node -v {-20 0,0 20,0 -20,20 0}
      '';
    };

  };
}