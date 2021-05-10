{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.wezterm;
  eitherStrBoolInt = with types; either str (either bool int);

  genericType = with types; oneOf [ str bool int float ];

  boolToStr = boolVal: if boolVal then "true" else "false";

  toWeztermKeybindings = bindings:
    let
      getMods = binding:
        optionalString (binding.modifiers != [ ])
        ''mods = "${builtins.concatStringsSep "|" binding.modifiers}",'';
      getAction = binding:
        optionalString (binding.action != "") "action = ${binding.action},";
      mapBinding = binding: ''
        {
          ${getMods binding}
          key = "${binding.key}",
          ${getAction binding}
        },'';
      # Map bindings to string
      mapped = builtins.map mapBinding bindings;
      # Join them together with indentation so it looks nice
      joined = builtins.concatStringsSep "\n" mapped;
      # Strip the trailing empty line
      trimmed = lib.strings.removeSuffix "\n" joined;
      # Remove empty lines
      stripped = builtins.replaceStrings [ "\n  \n" ] [ "\n" ] trimmed;
      # Indent properly
      indented = builtins.replaceStrings [ "\n" ] [ "\n    " ] stripped;
    in ''
      -- Keybinds
        keys = [
          ${indented}
        ],'';

  toWeztermMousebindings = bindings:
    let
      getMods = binding:
        optionalString (binding.modifiers != [ ])
        ''mods = "${builtins.concatStringsSep "|" binding.modifiers}",'';
      getAction = binding:
        optionalString (binding.action != "") "action = ${binding.action},";
      getEvent = binding: ''
        event = {
            ${binding.event} = {
              streak = ${toString binding.count},
              button = "${binding.button}",
            },
          },'';
      mapBinding = binding: ''
        {
          ${getMods binding}
          ${getEvent binding}
          ${getAction binding}
        },'';
      mapped = builtins.map mapBinding bindings;
      joined = builtins.concatStringsSep "\n" mapped;
      trimmed = lib.strings.removeSuffix "\n" joined;
      stripped = builtins.replaceStrings [ "\n  \n" ] [ "\n" ] trimmed;
      indented = builtins.replaceStrings [ "\n" ] [ "\n    " ] stripped;
    in ''
      -- Mouse Binds
        mouse_bindings = [
          ${indented}
        ],'';

  toWeztermTabColors = tab: indent:
    let
      formatted = ''
        {
          bg_color = "${tab.background}",
          fg_color = "${tab.foreground}",
          intensity = "${tab.intensity}",
          italic = ${boolToStr tab.italic},
          strikethrough = ${boolToStr tab.strikethrough},
          underline = "${tab.underline}",
        }''; # No comma bc they're added in toWeztermColorscheme
    in builtins.replaceStrings [ "\n" ] [''

      ${indent}''] formatted;

  toWeztermBase16Colors = colors:
    let
      nameList = attrsets.attrNames colors;
      values = attrsets.attrVals nameList colors;
      mapped = lists.forEach values (color: ''"${color}"'');
      joined = builtins.concatStringsSep ", " mapped;
    in "[ ${joined} ]";

  toWeztermColorscheme = colors: indent:
    let
      formatted = ''
        {
          foreground = "${colors.foreground}",
          background = "${colors.background}",
          cursor_bg = "${colors.cursor.background}",
          cursor_fg = "${colors.cursor.foreground}",
          cursor_border = "${colors.cursor.border}",
          selection_bg = "${colors.selection.background}",
          selection_fg = "${colors.selection.foreground}",
          scrollbar_thumb = "${colors.scrollbarThumb}",
          split = "${colors.split}",
          ansi = ${toWeztermBase16Colors colors.ansi},
          brights = ${toWeztermBase16Colors colors.bright},
          tab_bar = {
            background = "${colors.tabBar.background}",
            active_tab = ${
              toWeztermTabColors colors.tabBar.activeTab "${indent}  "
            },
            inactive_tab = ${
              toWeztermTabColors colors.tabBar.inactiveTab "${indent}  "
            },
            inactive_tab_hover = ${
              toWeztermTabColors colors.tabBar.inactiveTabHover "${indent}  "
            },
          },
        },'';
    in builtins.replaceStrings [ "\n" ] [''

      ${indent}''] formatted;

  toWeztermColors = colors: ''
    -- Colors
      colors = ${toWeztermColorscheme colors "  "}'';

  toWeztermConfig' = generators.toKeyValue {
    mkKeyValue = key: value:
      let
        value' = if isString value then
          ''"${value}"''
        else if isBool value # Bool formats to '0'/'1' with toString
        then
          (boolToStr value)
        else if isList value then
          ("")
        else
          toString value;
      in "${key} = ${value'},";
  };

  toWeztermConfig = config:
    let
      mapped = toWeztermConfig' config;
      indented = builtins.replaceStrings [ "\n" ] [ "\n  " ] mapped;
      trimmed = lib.strings.removeSuffix "\n  " indented;
    in ''
      -- Config
        ${trimmed}'';

  weztermKeybindType = with types;
    submodule {
      options = {
        modifiers = mkOption {
          type = listOf
            (enum [ "CTRL" "SUPER" "CMD" "WIN" "SHIFT" "ALT" "OPT" "LEADER" ]);
          default = [ ];
          description = ''
            The keybinding modifier key(s).
          '';
          example = literalExample ''
            [ "CTRL" "SHIFT" ]
          '';
        };

        key = mkOption {
          type = str;
          default = null;
          description = ''
            The keybinding main key.
          '';
          example = "l";
        };

        action = mkOption {
          type = str;
          default = "";
          description = ''
            The code called when the keybinding is executed.
          '';
          example = literalExample ''
            wezterm.action {ActivateTabRelative = 1}
          '';
        };
      };
    };

  weztermMousebindType = with types;
    submodule {
      options = {
        modifiers = mkOption {
          type = listOf
            (enum [ "CTRL" "SUPER" "CMD" "WIN" "SHIFT" "ALT" "OPT" "LEADER" ]);
          default = [ ];
          description = ''
            The mouse binding modifier key(s).
          '';
          example = literalExample ''
            [ "CTRL" ]
          '';
        };

        button = mkOption {
          type = enum [ "Left" "Right" "Middle" ];
          default = "Left";
          description = ''
            The mouse binding button.
          '';
          example = "Left";
        };

        event = mkOption {
          type = enum [ "Up" "Down" "Drag" ];
          default = "Left";
          description = ''
            The mouse binding event.
          '';
          example = "Left";
        };

        count = mkOption {
          type = int;
          default = 1;
          description = ''
            The event count to trigger action.
          '';
          example = 1;
        };

        action = mkOption {
          type = str;
          default = "";
          description = ''
            The code called when the keybinding is executed.
          '';
          example = literalExample ''
            "OpenLinkAtMouseCursor"
          '';
        };
      };
    };

  weztermColorschemeCursorType = with types;
    submodule {
      options = {
        foreground = mkOption {
          type = str;
          default = "#000000";
          description = ''
            Overrides the text color when the current cell is occupied by the cursor.
          '';
          example = "#000000";
        };

        background = mkOption {
          type = str;
          default = "#52AD70";
          description = ''
            Overrides the cell background color when the current cell is occupied by the cursor and the cursor style is set to Block.
          '';
          example = "#52AD70";
        };

        border = mkOption {
          type = str;
          default = "#52AD70";
          description = ''
            Specifies the border color of the cursor when the cursor style is set to Block,
            of the color of the vertical or horizontal bar when the cursor style is set to Bar or Underline.
          '';
          example = "#52AD70";
        };
      };
    };

  weztermColorschemeSelectionType = with types;
    submodule {
      options = {
        foreground = mkOption {
          type = str;
          default = "#000000";
          description = ''
            The foreground color of selected text.
          '';
          example = "#000000";
        };

        background = mkOption {
          type = str;
          default = "#FFFACD";
          description = ''
            The background color of selected text.
          '';
          example = "#FFFACD";
        };
      };
    };

  weztermColorschemeTabBarTabType = with types;
    tabType:
    submodule {
      options = {
        background = let
          default = if tabType == "active" then
            "#2B2042"
          else if tabType == "inactive" then
            "#1B1032"
          else
            "#3B3052";
        in mkOption {
          type = str;
          default = default;
          description = ''
            The color of the background area for the tab.
          '';
          example = default;
        };

        foreground = let
          default = if tabType == "active" then
            "#C0C0C0"
          else if tabType == "inactive" then
            "#808080"
          else
            "#909090";
        in mkOption {
          type = str;
          default = default;
          description = ''
            The color of the text for the tab.
          '';
          example = default;
        };

        intensity = mkOption {
          type = enum [ "Half" "Normal" "Bold" ];
          default = "Normal";
          description = ''
            Specify whether you want "Half", "Normal" or "Bold" intensity for the label shown for this tab.
            The default is "Normal".
          '';
          example = "Normal";
        };

        underline = mkOption {
          type = enum [ "None" "Single" "Double" ];
          default = "None";
          description = ''
            Specify whether you want "None", "Single" or "Double" underline for label shown for this tab.
            The default is "None".
          '';
          example = "None";
        };

        italic = let defaultStr = boolToStr (tabType == "inactive_hover");
        in mkOption {
          type = bool;
          default = (tabType == "inactive_hover");
          description = ''
            Specify whether you want the text to be italic (true) or not (false) for this tab. The default is ${defaultStr}.
          '';
          example = defaultStr;
        };

        strikethrough = mkOption {
          type = bool;
          default = false;
          description = ''
            Specify whether you want the text to be rendered with strikethrough (true) or not (false) for this tab. The default is false.
          '';
          example = "false";
        };
      };
    };

  weztermColorschemeTabBarType = with types;
    submodule {
      options = {
        background = mkOption {
          type = str;
          default = "#0B0022";
          description = ''
            The color of the strip that goes along the top of the window.
          '';
          example = "#0B0022";
        };

        activeTab = mkOption {
          type = weztermColorschemeTabBarTabType "active";
          default = { };
          description = ''
            Color the tab that has focus in the window.
          '';
          example = literalExample ''
            {
              background = "#2B2042";
              foreground = "#C0C0C0";
              intensity = "Bold";
              italic = false;
              strikethrough = false;
              underline = "None";
            }
          '';
        };

        inactiveTab = mkOption {
          type = weztermColorschemeTabBarTabType "inactive";
          default = { };
          description = ''
            Color the tabs that do not have focus.
          '';
          example = literalExample ''
            {
              background = "#1B1032";
              foreground = "#808080";
              intensity = "Normal";
              italic = false;
              strikethrough = false;
              underline = "None";
            }
          '';
        };

        inactiveTabHover = mkOption {
          type = weztermColorschemeTabBarTabType "inactive_hover";
          default = { };
          description = ''
            Color when the mouse pointer hovers over an inactive tab.
          '';
          example = literalExample ''
            {
              background = "#3B3052";
              foreground = "#909090";
              intensity = "Normal";
              italic = true;
              strikethrough = false;
              underline = "None";
            }
          '';
        };
      };
    };

  mkBase16Color = with types;
    colorName: isAnsi: defaultAnsi: defaultBright:
    let
      name = if isAnsi then "ansi" else "bright";
      default = if isAnsi then defaultAnsi else defaultBright;
    in mkOption {
      type = str;
      default = default;
      description = ''
        The ${name} ${colorName} color.
      '';
      example = default;
    };

  weztermColorschemeBase16Type = with types;
    isAnsi:
    submodule {
      options = {
        black = mkBase16Color "black" isAnsi "#000000" "#808080";
        red = mkBase16Color "red" isAnsi "#800000" "#FF0000";
        green = mkBase16Color "green" isAnsi "#008000" "#00FF00";
        yellow = mkBase16Color "yellow" isAnsi "#808000" "#FFFF00";
        blue = mkBase16Color "blue" isAnsi "#000080" "#0000FF";
        magenta = mkBase16Color "magenta" isAnsi "#800080" "#FF00FF";
        cyan = mkBase16Color "cyan" isAnsi "#008080" "#00FFFF";
        white = mkBase16Color "white" isAnsi "#C0C0C0" "#FFFFFF";
      };
    };

  weztermColorschemeType = with types;
    submodule {
      options = {
        foreground = mkOption {
          type = str;
          default = "#C0C0C0";
          description = ''
            The default text color.
          '';
          example = "#C0C0C0";
        };

        background = mkOption {
          type = str;
          default = "#000000";
          description = ''
            The default background color.
          '';
          example = "#000000";
        };

        cursor = mkOption {
          type = weztermColorschemeCursorType;
          default = { };
          description = ''
            The color of the cursor.
          '';
          example = literalExample ''
            {
              foreground = "#52ad70";
              background = "#000000";
              border = "#52AD70";
            }
          '';
        };

        selection = mkOption {
          type = weztermColorschemeSelectionType;
          default = { };
          description = ''
            The color of the selection.
          '';
          example = literalExample ''
            {
              foreground = "#FFFACD";
              background = "#000000";
            }
          '';
        };

        scrollbarThumb = mkOption {
          type = str;
          default = "#222222";
          description = ''
            The color of the scrollbar "thumb"; the portion that represents the current viewport
          '';
          example = "#222222";
        };

        split = mkOption {
          type = str;
          default = "#444444";
          description = ''
            The color of the split lines between panes
          '';
          example = "#444444";
        };

        tabBar = mkOption {
          type = weztermColorschemeTabBarType;
          default = { };
          description = ''
            The colors of the tab bar.
          '';
          example = literalExample ''
            {
              background = "#0b0022";
            }
          '';
        };

        ansi = mkOption {
          type = weztermColorschemeBase16Type true;
          default = { };
          description = ''
            The main ansi colors.
          '';
          example = literalExample ''
            {
              black = "#000000";
              red = "#800000";
              green = "#008000";
              yellow = "#808000";
              blue = "#000080";
              magenta = "#800080";
              cyan = "#008080";
              white = "#C0C0C0";
            }
          '';
        };

        bright = mkOption {
          type = weztermColorschemeBase16Type false;
          default = { };
          description = ''
            The main bright colors.
          '';
          example = literalExample ''
            {
              black = "#808080";
              red = "#FF0000";
              green = "#00FF00";
              yellow = "#FFFF00";
              blue = "#0000FF";
              magenta = "#FF00FF";
              cyan = "#00FFFF";
              white = "#FFFFFF";
            }
          '';
        };
      };
    };

in {
  meta.maintainers = with lib.maintainers; [ l3af ];

  options.programs.wezterm = with types; {
    enable = mkEnableOption "Wezterm terminal emulator";

    package = mkOption {
      type = package;
      default = pkgs.wezterm;
      defaultText = "pkgs.wezterm";
      description = ''
        Wezterm package to use. Set to <code>null</code> to use default package.
      '';
    };

    keybindings = mkOption {
      type = listOf weztermKeybindType;
      default = [ ];
      description = ''
        Mapping of keybindings to actions.
      '';
      example = literalExample ''
        [
          {
            modifiers = [ "SHIFT" "CTRL" ];
            key = "l";
            action = "wezterm.action {ActivateTabRelative = 1}";
          };
        ]
      '';
    };

    mousebindings = mkOption {
      type = listOf weztermMousebindType;
      default = [ ];
      description = ''
        Mapping of mouse bindings to actions.
      '';
      example = literalExample ''
        [
          {
            button = "Left";
            event = "Up";
            count = 1;
            modifiers = [ "CTRL" ];
            action = "\"OpenLinkAtMouseCursor\"";
          }
        ]
      '';
    };

    config = mkOption {
      type = attrsOf (either genericType (listOf genericType));
      default = { };
      description = ''
        Set any simple value.
      '';
      example = literalExample ''
        enable_wayland = true;
        font_size = 10.0;
        line_height = 1.0;
      '';
    };

    colors = mkOption {
      type = weztermColorschemeType;
      default = { };
      description = ''
        Set terminal colors.
      '';
      example = literalExample ''
        {
          foreground = "#C0C0C0";
          background = "#000000";
        }
      '';
    };

    extraConfig = mkOption {
      default = "";
      type = lines;
      description = ''
        Additional configuration to add to the return statement.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."wezterm/wezterm.lua".text = ''
      -- Generated by Home Manager.

      local wezterm = require("wezterm")

      return {
        ${
          optionalString (cfg.keybindings != [ ])
          (toWeztermKeybindings cfg.keybindings)
        }

        ${
          optionalString (cfg.mousebindings != [ ])
          (toWeztermMousebindings cfg.mousebindings)
        }

        ${optionalString (cfg.config != { }) (toWeztermConfig cfg.config)}

        ${toWeztermColors cfg.colors}

        ${cfg.extraConfig}
      }

    '';
  };
}
