{ config, lib, pkgs, ... }:

with lib;
with builtins;

let

  cfg = config.programs.rofi;

  colorOption = description: mkOption {
    type = types.string;
    description = description;
  };

  rowColorSubmodule = types.submodule {
    options = {
      background = colorOption "Background color";
      foreground = colorOption "Foreground color";
      backgroundAlt = colorOption "Alternative background color";
      highlight = mkOption {
        type = types.submodule {
          options = {
            background = colorOption "Highlight background color";
            foreground = colorOption "Highlight foreground color";
          };
        };
        description = "Color settings for highlighted row.";
      };
    };
  };

  windowColorSubmodule = types.submodule {
    options = {
      background = colorOption "Window background color";
      border = colorOption "Window border color";
      separator = colorOption "Separator color";
    };
  };

  colorsSubmodule = types.submodule {
    options = {
      window = mkOption {
        default = null;
        type = windowColorSubmodule;
        description = "Window color settings.";
      };
      rows = mkOption {
        default = null;
        type = types.submodule {
          options = {
            normal = mkOption {
              default = null;
              type = types.nullOr rowColorSubmodule;
              description = "Normal row color settings.";
            };
            active = mkOption {
              default = null;
              type = types.nullOr rowColorSubmodule;
              description = "Active row color settings.";
            };
            urgent = mkOption {
              default = null;
              type = types.nullOr rowColorSubmodule;
              description = "Urgent row color settings.";
            };
          };
        };
        description = "Rows color settings.";
      };
    };
  };

  valueToString = value:
    if isBool value
      then (if value then "true" else "else")
      else toString value;

  windowColorsToString = window: concatStringsSep ", " (with window; [
    background
    border
    separator
  ]);

  rowsColorsToString = rows: ''
    ${optionalString
        (rows.normal != null)
        (setOption "color-normal" (rowColorsToString rows.normal))}
    ${optionalString
        (rows.active != null)
        (setOption "color-active" (rowColorsToString rows.active))}
    ${optionalString
        (rows.urgent != null)
        (setOption "color-urgent" (rowColorsToString rows.urgent))}
  '';

  rowColorsToString = row: concatStringsSep ", " (with row; [
    background
    foreground
    backgroundAlt
    highlight.background
    highlight.foreground
  ]);

  setOption = name: value:
    optionalString (value != null) "rofi.${name}: ${valueToString value}";

  setColorScheme = colors: optionalString (colors != null) ''
    ${optionalString
        (colors.window != null)
        setOption "color-window" (windowColorsToString colors.window)}
    ${optionalString
        (colors.rows != null)
        (rowsColorsToString colors.rows)}
  '';

in

{
  options.programs.rofi = {
    enable = mkEnableOption "Rofi: A window switcher, application launcher and dmenu replacement";

    width = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Window width";
      example = 100;
    };

    lines = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Number of lines";
      example = 10;
    };

    borderWidth = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Border width";
      example = 1;
    };

    rowHeight = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Row height (in chars)";
      example = 1;
    };

    padding = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Padding";
      example = 400;
    };

    font = mkOption {
      default = null;
      type = types.nullOr types.string;
      example = "Droid Sans Mono 14";
      description = "Font to use.";
    };

    scrollbar = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to show a scrollbar.";
    };

    terminal = mkOption {
      default = null;
      type = types.nullOr types.string;
      description = ''
        Path to the terminal which will be used to run console applications
      '';
      example = "\${pkgs.gnome3.gnome_terminal}/bin/gnome-terminal";
    };

    separator = mkOption {
      default = null;
      type = types.nullOr (types.enum [ "none" "dash" "solid" ]);
      description = "Separator style";
      example = "solid";
    };

    cycle = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to cycle through the results list.";
    };

    fullscreen = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to run rofi fullscreen.";
    };

    colors = mkOption {
      default = null;
      type = types.nullOr colorsSubmodule;
      description = ''
        Color scheme settings.
        Colors can be specified in CSS color formats.
      '';
      example = literalExample ''
        colors = {
          window = {
            background = "argb:583a4c54";
            border = "argb:582a373e";
            separator = "#c3c6c8";
          };

          rows = {
            normal = {
              background = "argb:58455a64";
              foreground = "#fafbfc";
              backgroundAlt = "argb:58455a64";
              highlight = {
                background = "#00bcd4";
                foreground = "#fafbfc";
              };
            };
          };
        };
      '';
    };

    theme = mkOption {
      default = null;
      type = types.nullOr types.string;
      description = "Name of theme to use";
      example = "Arc";
    };

    configPath = mkOption {
      default = ".config/rofi/config";
      type = types.string;
      description = "Path where to put generated configuration file.";
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
    };

  };

  config = mkIf cfg.enable {
    warnings = optional (cfg.theme != null && cfg.colors != null) "rofi: colors shouldn't be set when using themes";
    home.packages = [ pkgs.rofi ];

    home.file."${cfg.configPath}".text = ''
      ${setOption "width" cfg.width}
      ${setOption "lines" cfg.lines}
      ${setOption "font" cfg.font}
      ${setOption "bw" cfg.borderWidth}
      ${setOption "eh" cfg.rowHeight}
      ${setOption "padding" cfg.padding}
      ${setOption "separator-style" cfg.separator}
      ${setOption "hide-scrollbar" (
        if (cfg.scrollbar != null)
        then (! cfg.scrollbar)
        else cfg.scrollbar
      )}
      ${setOption "terminal" cfg.terminal}
      ${setOption "cycle" cfg.cycle}
      ${setOption "fullscreen" cfg.fullscreen}

      ${setColorScheme cfg.colors}
      ${setOption "theme" cfg.theme}

      ${cfg.extraConfig}
    '';
  };
}
