{ config, lib, pkgs, ... }:

with lib;
with builtins;

let

  cfg = config.programs.rofi;

  colorOption = description: mkOption {
    type = types.str;
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

  locationsMap = {
    center       = 0;
    top-left     = 1;
    top          = 2;
    top-right    = 3;
    right        = 4;
    bottom-right = 5;
    bottom       = 6;
    bottom-left  = 7;
    left         = 8;
  };

  themeName =
    if (cfg.theme == null) then null
    else if (lib.isString cfg.theme) then cfg.theme
    else lib.removeSuffix ".rasi" (baseNameOf cfg.theme);

  themePath = if (lib.isString cfg.theme) then null else cfg.theme;

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
      type = types.nullOr types.str;
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
      type = types.nullOr types.str;
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

    location = mkOption {
      default = "center";
      type = types.enum (builtins.attrNames locationsMap);
      description = "The location rofi appears on the screen.";
    };

    xoffset = mkOption {
      default = 0;
      type = types.int;
      description = ''
        Offset in the x-axis in pixels relative to the chosen location.
      '';
    };

    yoffset = mkOption {
      default = 0;
      type = types.int;
      description = ''
        Offset in the y-axis in pixels relative to the chosen location.
      '';
    };

    colors = mkOption {
      default = null;
      type = types.nullOr colorsSubmodule;
      description = ''
        Color scheme settings. Colors can be specified in CSS color
        formats. This option may become deprecated in the future and
        therefore the <varname>programs.rofi.theme</varname> option
        should be used whenever possible.
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
      type = with types; nullOr (either str path);
      example = "Arc";
      description = ''
        Name of theme or path to theme file in rasi format. Available
        named themes can be viewed using the
        <command>rofi-theme-selector</command> tool.
      '';
    };

    configPath = mkOption {
      default = "${config.xdg.configHome}/rofi/config";
      defaultText = "$XDG_CONFIG_HOME/rofi/config";
      type = types.str;
      description = "Path where to put generated configuration file.";
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.theme == null || cfg.colors == null;
        message = ''
          Cannot use the rofi options 'theme' and 'colors' simultaneously.
        '';
      }
    ];

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
      ${setOption "location" (builtins.getAttr cfg.location locationsMap)}
      ${setOption "xoffset" cfg.xoffset}
      ${setOption "yoffset" cfg.yoffset}

      ${setColorScheme cfg.colors}
      ${setOption "theme" themeName}

      ${cfg.extraConfig}
    '';

    xdg.dataFile = mkIf (themePath != null) {
      "rofi/themes/${themeName}.rasi".source =  themePath;
    };
  };
}
