{ config, lib, pkgs, ... }:

let
  inherit (lib) all filterAttrs isStorePath literalExpression types;
  inherit (lib.options) mkEnableOption mkPackageOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.strings) concatMapStrings;
  inherit (builtins) toJSON;

  cfg = config.programs.wlogout;

  jsonFormat = pkgs.formats.json { };

  wlogoutLayoutConfig = with types;
    submodule {
      freeformType = jsonFormat.type;

      options = {
        label = mkOption {
          type = str;
          default = "";
          example = "shutdown";
          description = "CSS label of button.";
        };

        action = mkOption {
          type = either path str;
          default = "";
          example = "systemctl poweroff";
          description = "Command to execute when clicked.";
        };

        text = mkOption {
          type = str;
          default = "";
          example = "Shutdown";
          description = "Text displayed on button.";
        };

        keybind = mkOption {
          type = str;
          default = "";
          example = "s";
          description = "Keyboard character to trigger this action.";
        };

        height = mkOption {
          type = nullOr (numbers.between 0 1);
          default = null;
          example = 0.5;
          description = "Relative height of tile.";
        };

        width = mkOption {
          type = nullOr (numbers.between 0 1);
          default = null;
          example = 0.5;
          description = "Relative width of tile.";
        };

        circular = mkOption {
          type = nullOr bool;
          default = null;
          example = true;
          description = "Make button circular.";
        };
      };
    };
in {
  meta.maintainers = [ lib.maintainers.Scrumplex ];

  options.programs.wlogout = with lib.types; {
    enable = mkEnableOption "wlogout";

    package = mkPackageOption pkgs "wlogout" { };

    layout = mkOption {
      type = listOf wlogoutLayoutConfig;
      default = [ ];
      description = ''
        Layout configuration for wlogout, see <link
          xlink:href="https://github.com/ArtsyMacaw/wlogout#config"/>
        for supported values.
      '';
      example = literalExpression ''
        [
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "s";
          }
        ]
      '';
    };

    style = mkOption {
      type = nullOr (either path str);
      default = null;
      description = ''
        CSS style of the bar.
        </para>
        <para>
        See <link xlink:href="https://github.com/ArtsyMacaw/wlogout#style"/>
        for the documentation.
        </para>
        <para>
        If the value is set to a path literal, then the path will be used as the css file.
      '';
      example = ''
        window {
          background: #16191C;
        }

        button {
          color: #AAB2BF;
        }
      '';
    };
  };

  config = let
    # Removes nulls because wlogout ignores them.
    # This is not recursive.
    removeTopLevelNulls = filterAttrs (_: v: v != null);
    cleanJSON = foo: toJSON (removeTopLevelNulls foo);

    # wlogout doesn't want a JSON array, it just wants a list of JSON objects
    layoutJsons = map cleanJSON cfg.layout;
    layoutContent = concatMapStrings (l: l + "\n") layoutJsons;

  in mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.wlogout" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."wlogout/layout" = mkIf (cfg.layout != [ ]) {
      source = pkgs.writeText "wlogout/layout" layoutContent;
    };

    xdg.configFile."wlogout/style.css" = mkIf (cfg.style != null) {
      source = if builtins.isPath cfg.style || isStorePath cfg.style then
        cfg.style
      else
        pkgs.writeText "wlogout/style.css" cfg.style;
    };
  };
}
