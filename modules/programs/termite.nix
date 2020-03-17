{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.termite;

  vteInitStr = ''
    # See https://github.com/thestinger/termite#id1
    if [[ $TERM == xterm-termite ]]; then
      . ${pkgs.termite.vte-ng}/etc/profile.d/vte.sh
    fi
  '';

in {
  options = {
    programs.termite = {
      enable = mkEnableOption "Termite VTE-based terminal";

      allowBold = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Allow the output of bold characters when the bold escape sequence appears.
        '';
      };

      audibleBell = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = "Have the terminal beep on the terminal bell.";
      };

      clickableUrl = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Auto-detected URLs can be clicked on to open them in  your browser.
          Only enabled if a browser is configured or detected.
        '';
      };

      dynamicTitle = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Settings dynamic title allows the terminal and the shell to
          update the terminal's title.
        '';
      };

      fullscreen = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = "Enables entering fullscreen mode by pressing F11.";
      };

      mouseAutohide = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Automatically hide the mouse pointer when you start typing.
        '';
      };

      scrollOnOutput = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = "Scroll to the bottom when the shell generates output.";
      };

      scrollOnKeystroke = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Scroll to the bottom automatically when a key is pressed.
        '';
      };

      searchWrap = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = "Search from top again when you hit the bottom.";
      };

      urgentOnBell = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = "Sets the window as urgent on the terminal bell.";
      };

      font = mkOption {
        default = null;
        example = "Monospace 12";
        type = types.nullOr types.str;
        description = "The font description for the terminal's font.";
      };

      geometry = mkOption {
        default = null;
        example = "640x480";
        type = types.nullOr types.str;
        description = "The default window geometry for new terminal windows.";
      };

      iconName = mkOption {
        default = null;
        example = "terminal";
        type = types.nullOr types.str;
        description =
          "The name of the icon to be used for the terminal process.";
      };

      scrollbackLines = mkOption {
        default = null;
        example = 10000;
        type = types.nullOr types.int;
        description =
          "Set the number of lines to limit the terminal's scrollback.";
      };

      browser = mkOption {
        default = null;
        type = types.nullOr types.str;
        example = "${pkgs.xdg_utils}/xdg-open";
        description = ''
          Set the default browser for opening links. If its not set, $BROWSER is read.
          If that's not set, url hints will be disabled.
        '';
      };

      cursorBlink = mkOption {
        default = null;
        example = "system";
        type = types.nullOr (types.enum [ "system" "on" "off" ]);
        description = ''
          Specify the how the terminal's cursor should behave.
          Accepts system to respect the gtk global configuration,
          on and off to explicitly enable or disable them.
        '';
      };

      cursorShape = mkOption {
        default = null;
        example = "block";
        type = types.nullOr (types.enum [ "block" "underline" "ibeam" ]);
        description = ''
          Specify how the cursor should look. Accepts block, ibeam and underline.
        '';
      };

      filterUnmatchedUrls = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description =
          "Whether to hide url hints not matching input in url hints mode.";
      };

      modifyOtherKeys = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Emit escape sequences for extra keys,
          like the modifyOtherKeys resource for
          <citerefentry>
            <refentrytitle>xterm</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>.
        '';
      };

      sizeHints = mkOption {
        default = null;
        type = types.nullOr types.bool;
        description = ''
          Enable size hints. Locks the terminal resizing
          to increments of the terminal's cell size.
          Requires a window manager that respects scroll hints.
        '';
      };

      scrollbar = mkOption {
        default = null;
        type = types.nullOr (types.enum [ "off" "left" "right" ]);
        description = "Scrollbar position.";
      };

      backgroundColor = mkOption {
        default = null;
        example = "rgba(63, 63, 63, 0.8)";
        type = types.nullOr types.str;
        description = "Background color value.";
      };

      cursorColor = mkOption {
        default = null;
        example = "#dcdccc";
        type = types.nullOr types.str;
        description = "Cursor color value.";
      };

      cursorForegroundColor = mkOption {
        default = null;
        example = "#dcdccc";
        type = types.nullOr types.str;
        description = "Cursor foreground color value.";
      };

      foregroundColor = mkOption {
        default = null;
        example = "#dcdccc";
        type = types.nullOr types.str;
        description = "Foreground color value.";
      };

      foregroundBoldColor = mkOption {
        default = null;
        example = "#ffffff";
        type = types.nullOr types.str;
        description = "Foreground bold color value.";
      };

      highlightColor = mkOption {
        default = null;
        example = "#2f2f2f";
        type = types.nullOr types.str;
        description = "highlight color value.";
      };

      hintsActiveBackgroundColor = mkOption {
        default = null;
        example = "#3f3f3f";
        type = types.nullOr types.str;
        description = "Hints active background color value.";
      };

      hintsActiveForegroundColor = mkOption {
        default = null;
        example = "#e68080";
        type = types.nullOr types.str;
        description = "Hints active foreground color value.";
      };

      hintsBackgroundColor = mkOption {
        default = null;
        example = "#3f3f3f";
        type = types.nullOr types.str;
        description = "Hints background color value.";
      };

      hintsForegroundColor = mkOption {
        default = null;
        example = "#dcdccc";
        type = types.nullOr types.str;
        description = "Hints foreground color value.";
      };

      hintsBorderColor = mkOption {
        default = null;
        example = "#3f3f3f";
        type = types.nullOr types.str;
        description = "Hints border color value.";
      };

      hintsBorderWidth = mkOption {
        default = null;
        example = "0.5";
        type = types.nullOr types.str;
        description = "Hints border width.";
      };

      hintsFont = mkOption {
        default = null;
        example = "Monospace 12";
        type = types.nullOr types.str;
        description = "The font description for the hints font.";
      };

      hintsPadding = mkOption {
        default = null;
        example = 2;
        type = types.nullOr types.int;
        description = "Hints padding.";
      };

      hintsRoundness = mkOption {
        default = null;
        example = "0.2";
        type = types.nullOr types.str;
        description = "Hints roundness.";
      };

      optionsExtra = mkOption {
        default = "";
        example = "fullscreen = true";
        type = types.lines;
        description =
          "Extra options that should be added to [options] section.";
      };

      colorsExtra = mkOption {
        default = "";
        example = ''
          color0 = #3f3f3f
          color1 = #705050
          color2 = #60b48a
        '';
        type = types.lines;
        description =
          "Extra colors options that should be added to [colors] section.";
      };

      hintsExtra = mkOption {
        default = "";
        example = "border = #3f3f3f";
        type = types.lines;
        description =
          "Extra hints options that should be added to [hints] section.";
      };
    };
  };

  config = (let
    boolToString = v: if v then "true" else "false";
    optionalBoolean = name: val:
      lib.optionalString (val != null) "${name} = ${boolToString val}";
    optionalInteger = name: val:
      lib.optionalString (val != null) "${name} = ${toString val}";
    optionalString = name: val:
      lib.optionalString (val != null) "${name} = ${val}";
  in mkIf cfg.enable {
    home.packages = [ pkgs.termite ];
    xdg.configFile."termite/config".text = ''
      [options]
      ${optionalBoolean "allow_bold" cfg.allowBold}
      ${optionalBoolean "audible_bell" cfg.audibleBell}
      ${optionalString "browser" cfg.browser}
      ${optionalBoolean "clickable_url" cfg.clickableUrl}
      ${optionalString "cursor_blink" cfg.cursorBlink}
      ${optionalString "cursor_shape" cfg.cursorShape}
      ${optionalBoolean "dynamic_title" cfg.dynamicTitle}
      ${optionalBoolean "filter_unmatched_urls" cfg.filterUnmatchedUrls}
      ${optionalString "font" cfg.font}
      ${optionalBoolean "fullscreen" cfg.fullscreen}
      ${optionalString "geometry" cfg.geometry}
      ${optionalString "icon_name" cfg.iconName}
      ${optionalBoolean "modify_other_keys" cfg.modifyOtherKeys}
      ${optionalBoolean "mouse_autohide" cfg.mouseAutohide}
      ${optionalBoolean "scroll_on_keystroke" cfg.scrollOnKeystroke}
      ${optionalBoolean "scroll_on_output" cfg.scrollOnOutput}
      ${optionalInteger "scrollback_lines" cfg.scrollbackLines}
      ${optionalString "scrollbar" cfg.scrollbar}
      ${optionalBoolean "search_wrap" cfg.searchWrap}
      ${optionalBoolean "size_hints" cfg.sizeHints}
      ${optionalBoolean "urgent_on_bell" cfg.urgentOnBell}

      ${cfg.optionsExtra}

      [colors]
      ${optionalString "background" cfg.backgroundColor}
      ${optionalString "cursor" cfg.cursorColor}
      ${optionalString "cursor_foreground" cfg.cursorForegroundColor}
      ${optionalString "foreground" cfg.foregroundColor}
      ${optionalString "foreground_bold" cfg.foregroundBoldColor}
      ${optionalString "highlight" cfg.highlightColor}

      ${cfg.colorsExtra}

      [hints]
      ${optionalString "active_background" cfg.hintsActiveBackgroundColor}
      ${optionalString "active_foreground" cfg.hintsActiveForegroundColor}
      ${optionalString "background" cfg.hintsBackgroundColor}
      ${optionalString "border" cfg.hintsBorderColor}
      ${optionalInteger "border_width" cfg.hintsBorderWidth}
      ${optionalString "font" cfg.hintsFont}
      ${optionalString "foreground" cfg.hintsForegroundColor}
      ${optionalInteger "padding" cfg.hintsPadding}
      ${optionalInteger "roundness" cfg.hintsRoundness}

      ${cfg.hintsExtra}
    '';

    programs.bash.initExtra = vteInitStr;
    programs.zsh.initExtra = vteInitStr;
  });
}
