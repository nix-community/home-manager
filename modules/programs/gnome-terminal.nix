{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gnome-terminal;

  vteInitStr = ''
    # gnome-terminal: Show current directory in the terminal window title.
    . ${pkgs.gnome3.vte}/etc/profile.d/vte.sh
  '';

  backForeSubModule = types.submodule ({ ... }: {
    options = {
      foreground = mkOption {
        type = types.str;
        description = "The foreground color.";
      };

      background = mkOption {
        type = types.str;
        description = "The background color.";
      };
    };
  });

  profileColorsSubModule = types.submodule ({ ... }: {
    options = {
      foregroundColor = mkOption {
        type = types.str;
        description = "The foreground color.";
      };

      backgroundColor = mkOption {
        type = types.str;
        description = "The background color.";
      };

      boldColor = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = "The bold color, null to use same as foreground.";
      };

      palette = mkOption {
        type = types.listOf types.str;
        description = "The terminal palette.";
      };

      cursor = mkOption {
        default = null;
        type = types.nullOr backForeSubModule;
        description = "The color for the terminal cursor.";
      };

      highlight = mkOption {
        default = null;
        type = types.nullOr backForeSubModule;
        description = "The colors for the terminal’s highlighted area.";
      };
    };
  });

  profileSubModule = types.submodule ({ name, config, ... }: {
    options = {
      default = mkOption {
        default = false;
        type = types.bool;
        description = "Whether this should be the default profile.";
      };

      visibleName = mkOption {
        type = types.str;
        description = "The profile name.";
      };

      colors = mkOption {
        default = null;
        type = types.nullOr profileColorsSubModule;
        description = "The terminal colors, null to use system default.";
      };

      cursorBlinkMode = mkOption {
        default = "system";
        type = types.enum [ "system" "on" "off" ];
        description = "The cursor blink mode.";
      };

      cursorShape = mkOption {
        default = "block";
        type = types.enum [ "block" "ibeam" "underline" ];
        description = "The cursor shape.";
      };

      font = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = "The font name, null to use system default.";
      };

      allowBold = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          If <literal>true</literal>, allow applications in the
          terminal to make text boldface.
        '';
      };

      scrollOnOutput = mkOption {
        default = true;
        type = types.bool;
        description = "Whether to scroll when output is written.";
      };

      showScrollbar = mkOption {
        default = true;
        type = types.bool;
        description = "Whether the scroll bar should be visible.";
      };

      scrollbackLines = mkOption {
        default = 10000;
        type = types.nullOr types.int;
        description = ''
          The number of scrollback lines to keep, null for infinite.
        '';
      };
    };
  });

  buildProfileSet = pcfg:
    {
      visible-name = pcfg.visibleName;
      scrollbar-policy = if pcfg.showScrollbar then "always" else "never";
      scrollback-lines = pcfg.scrollbackLines;
      cursor-shape = pcfg.cursorShape;
      cursor-blink-mode = pcfg.cursorBlinkMode;
    } // (if (pcfg.font == null) then {
      use-system-font = true;
    } else {
      use-system-font = false;
      font = pcfg.font;
    }) // (if (pcfg.colors == null) then {
      use-theme-colors = true;
    } else
      ({
        use-theme-colors = false;
        foreground-color = pcfg.colors.foregroundColor;
        background-color = pcfg.colors.backgroundColor;
        palette = pcfg.colors.palette;
      } // optionalAttrs (pcfg.allowBold != null) {
        allow-bold = pcfg.allowBold;
      } // (if (pcfg.colors.boldColor == null) then {
        bold-color-same-as-fg = true;
      } else {
        bold-color-same-as-fg = false;
        bold-color = pcfg.colors.boldColor;
      }) // (if (pcfg.colors.cursor != null) then {
        cursor-colors-set = true;
        cursor-foreground-color = pcfg.colors.cursor.foreground;
        cursor-background-color = pcfg.colors.cursor.background;
      } else {
        cursor-colors-set = false;
      }) // (if (pcfg.colors.highlight != null) then {
        highlight-colors-set = true;
        highlight-foreground-color = pcfg.colors.highlight.foreground;
        highlight-background-color = pcfg.colors.highlight.background;
      } else {
        highlight-colors-set = false;
      })));

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.gnome-terminal = {
      enable = mkEnableOption "Gnome Terminal";

      showMenubar = mkOption {
        default = true;
        type = types.bool;
        description = "Whether to show the menubar by default";
      };

      themeVariant = mkOption {
        default = "default";
        type = types.enum [ "default" "light" "dark" ];
        description = "The theme variation to request";
      };

      profile = mkOption {
        default = { };
        type = types.attrsOf profileSubModule;
        description = "A set of Gnome Terminal profiles.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gnome3.gnome_terminal ];

    dconf.settings = let dconfPath = "org/gnome/terminal/legacy";
    in {
      "${dconfPath}" = {
        default-show-menubar = cfg.showMenubar;
        theme-variant = cfg.themeVariant;
        schema-version = 3;
      };

      "${dconfPath}/profiles:" = {
        default = head (attrNames (filterAttrs (n: v: v.default) cfg.profile));
        list = attrNames cfg.profile;
      };
    } // mapAttrs'
    (n: v: nameValuePair ("${dconfPath}/profiles:/:${n}") (buildProfileSet v))
    cfg.profile;

    programs.bash.initExtra = mkBefore vteInitStr;
    programs.zsh.initExtra = vteInitStr;
  };
}
