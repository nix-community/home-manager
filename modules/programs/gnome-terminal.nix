{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.gnome-terminal;

  eraseBinding = types.enum [
    "auto"
    "ascii-backspace"
    "ascii-delete"
    "delete-sequence"
    "tty"
  ];

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

      customCommand = mkOption {
        default = null;
        type = types.nullOr types.str;
        description = ''
          The command to use to start the shell, or null for default shell.
        '';
      };

      loginShell = mkOption {
        default = false;
        type = types.bool;
        description = "Run command as a login shell.";
      };

      backspaceBinding = mkOption {
        default = "ascii-delete";
        type = eraseBinding;
        description = ''
          Which string the terminal should send to an application when the user
          presses the <emphasis>Backspace</emphasis> key.

          <variablelist>
            <varlistentry>
              <term><literal>auto</literal></term>
              <listitem><para>
                Attempt to determine the right value from the terminal's IO settings.
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>ascii-backspace</literal></term>
              <listitem><para>
                Send an ASCII backspace character (0x08).
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>ascii-delete</literal></term>
              <listitem><para>
                Send an ASCII delete character (0x7F).
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>delete-sequence</literal></term>
              <listitem><para>
                Send the <quote>@7</quote> control sequence.
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>tty</literal></term>
              <listitem><para>
                Send terminal’s <quote>erase</quote> setting.
              </para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      boldIsBright = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = "Whether bold text is shown in bright colors.";
      };

      deleteBinding = mkOption {
        default = "delete-sequence";
        type = eraseBinding;
        description = ''
          Which string the terminal should send to an application when the user
          presses the <emphasis>Delete</emphasis> key.

          <variablelist>
            <varlistentry>
              <term><literal>auto</literal></term>
              <listitem><para>
                Send the <quote>@7</quote> control sequence.
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>ascii-backspace</literal></term>
              <listitem><para>
                Send an ASCII backspace character (0x08).
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>ascii-delete</literal></term>
              <listitem><para>
                Send an ASCII delete character (0x7F).
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>delete-sequence</literal></term>
              <listitem><para>
                Send the <quote>@7</quote> control sequence.
              </para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>tty</literal></term>
              <listitem><para>
                Send terminal’s <quote>erase</quote> setting.
              </para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      audibleBell = mkOption {
        default = true;
        type = types.bool;
        description = "Turn on/off the terminal's bell.";
      };

      transparencyPercent = mkOption {
        default = null;
        type = types.nullOr (types.ints.between 0 100);
        description = "Background transparency in percent.";
      };
    };
  });

  buildProfileSet = pcfg:
    {
      audible-bell = pcfg.audibleBell;
      visible-name = pcfg.visibleName;
      scroll-on-output = pcfg.scrollOnOutput;
      scrollbar-policy = if pcfg.showScrollbar then "always" else "never";
      scrollback-lines = pcfg.scrollbackLines;
      cursor-shape = pcfg.cursorShape;
      cursor-blink-mode = pcfg.cursorBlinkMode;
      login-shell = pcfg.loginShell;
      backspace-binding = pcfg.backspaceBinding;
      delete-binding = pcfg.deleteBinding;
    } // (if (pcfg.customCommand != null) then {
      use-custom-command = true;
      custom-command = pcfg.customCommand;
    } else {
      use-custom-command = false;
    }) // (if (pcfg.font == null) then {
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
      }) // optionalAttrs (pcfg.boldIsBright != null) {
        bold-is-bright = pcfg.boldIsBright;
      } // (if (pcfg.colors.cursor != null) then {
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
      }) // optionalAttrs (pcfg.transparencyPercent != null) {
        background-transparency-percent = pcfg.transparencyPercent;
        use-theme-transparency = false;
        use-transparent-background = true;
      }));

in {
  meta.maintainers = with maintainers; [ kamadorueda rycee ];

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
        type = types.enum [ "default" "light" "dark" "system" ];
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
    home.packages = [ pkgs.gnome.gnome-terminal ];

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

    programs.bash.enableVteIntegration = true;
    programs.zsh.enableVteIntegration = true;
  };
}
