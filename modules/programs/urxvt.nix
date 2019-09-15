{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.urxvt;

in

{
  options.programs.urxvt = {
    enable = mkEnableOption "rxvt-unicode terminal emulator";

    package = mkOption {
      type = types.package;
      default = pkgs.rxvt_unicode;
      defaultText = literalExample "pkgs.rxvt_unicode";
      description = "rxvt-unicode package to install.";
    };

    fonts = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of fonts to be used.";
      example = [ "xft:Droid Sans Mono Nerd Font:size=9" ];
    };

    keybindings = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Mapping of keybindings to actions";
      example = literalExample ''
        {
          "Shift-Control-C" = "eval:selection_to_clipboard";
          "Shift-Control-V" = "eval:paste_clipboard";
        }
      '';
    };

    iso14755 = mkOption {
      type = types.bool;
      default = true;
      description = "ISO14755 support for viewing and entering unicode characters.";
    };

    scroll = {
      bar = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to enable the scrollbar";
            };

            style = mkOption {
              type = types.enum [ "rxvt" "plain" "next" "xterm" ];
              default = "plain";
              description = "Scrollbar style.";
            };

            align = mkOption {
              type = types.enum [ "top" "bottom" "center" ];
              default = "center";
              description = "Scrollbar alignment.";
            };

            position = mkOption {
              type = types.enum [ "left" "right" ];
              default = "right";
              description = "Scrollbar position.";
            };

            floating = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to display an rxvt scrollbar without a trough.";
            };
          };
        };
        default = {};
        description = "Scrollbar settings.";
      };

      lines = mkOption {
        type = types.ints.unsigned;
        default = 10000;
        description = "Number of lines to save in the scrollback buffer.";
      };

      keepPosition = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to keep a scroll position when TTY receives new lines.";
      };

      scrollOnKeystroke = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to scroll to bottom on keyboard input.";
      };

      scrollOnOutput = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to scroll to bottom on TTY output.";
      };
    };

    transparent = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable pseudo-transparency.";
    };

    shading = mkOption {
      type = types.ints.between 0 200;
      default = 100;
      description = "Darken (0 .. 99) or lighten (101 .. 200) the transparent background.";
    };

    extraConfig = mkOption {
      default = {};
      type = types.attrs;
      description = "Additional configuration to add.";
      example = { "shading" = 15; };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xresources.properties = {
      "URxvt.scrollBar" = cfg.scroll.bar.enable;
      "URxvt.scrollstyle" = cfg.scroll.bar.style;
      "URxvt.scrollBar_align" = cfg.scroll.bar.align;
      "URxvt.scrollBar_right" = cfg.scroll.bar.position == "right";
      "URxvt.scrollBar_floating" = cfg.scroll.bar.floating;
      "URxvt.saveLines" = cfg.scroll.lines;
      "URxvt.scrollWithBuffer" = cfg.scroll.keepPosition;
      "URxvt.scrollTtyKeypress" = cfg.scroll.scrollOnKeystroke;
      "URxvt.scrollTtyOutput" = cfg.scroll.scrollOnOutput;
      "URxvt.transparent" = cfg.transparent;
      "URxvt.shading" = cfg.shading;
      "URxvt.iso14755" = cfg.iso14755;
    } // flip mapAttrs' cfg.keybindings (kb: action:
     nameValuePair "URxvt.keysym.${kb}" action
    ) // optionalAttrs (cfg.fonts != []) {
      "URxvt.font" = concatStringsSep "," cfg.fonts;
    } // flip mapAttrs' cfg.extraConfig (k: v:
      nameValuePair "URxvt.${k}" v
    );
  };
}
