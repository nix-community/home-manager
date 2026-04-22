{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.rectangle;

  jsonFormat = pkgs.formats.json { };

  modifierFlagsMap = {
    "shift" = 131072;
    "ctrl" = 262144;
    "option" = 524288;
    "ctrl+option" = 786432;
    "ctrl+option+shift" = 917504;
    "command" = 1048576;
    "shift+command" = 1179648;
    "ctrl+option+command" = 1835008;
    "ctrl+option+shift+command" = 1966080;
  };
in
{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  options.programs.rectangle = {
    enable = lib.mkEnableOption "Rectangle window manager";

    package = lib.mkPackageOption pkgs "rectangle" { nullable = true; };

    defaults = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          launchOnLogin = { bool = true; };
          gapSize = { float = 8.0; };
          windowSnapping = { int = 1; };
          almostMaximizeHeight = { float = 0.9; };
          almostMaximizeWidth = { float = 0.9; };
        }
      '';
      description = ''
        Rectangle application defaults. Each attribute name is a setting key
        and its value must be wrapped in a type tag:
        `{ bool = …; }`, `{ float = …; }`, or `{ int = …; }`.

        Written to
        {file}`~/Library/Application Support/Rectangle/RectangleConfig.json`
        and importable via Rectangle -> Import Config.

        See <https://github.com/rxhanson/Rectangle> for the full list of
        available settings.
      '';
    };

    shortcuts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            keyCode = lib.mkOption {
              type = lib.types.int;
              description = "macOS virtual key code for this shortcut.";
            };

            modifierFlags = lib.mkOption {
              type = lib.types.enum (builtins.attrNames modifierFlagsMap);
              description = ''
                Modifier key combination for this shortcut. One of:
                - `"shift"` (⇧)
                - `"ctrl"` (⌃)
                - `"option"` (⌥)
                - `"ctrl+option"` (⌃⌥)
                - `"ctrl+option+shift"` (⌃⌥⇧)
                - `"command"` (⌘)
                - `"shift+command"` (⇧⌘)
                - `"ctrl+option+command"` (⌃⌥⌘)
                - `"ctrl+option+shift+command"` (⌃⌥⇧⌘)
              '';
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          leftHalf   = { keyCode = 123; modifierFlags = "ctrl+option+command"; };
          rightHalf  = { keyCode = 124; modifierFlags = "ctrl+option+command"; };
          topHalf    = { keyCode = 126; modifierFlags = "ctrl+option+command"; };
          bottomHalf = { keyCode = 125; modifierFlags = "ctrl+option+command"; };
          maximize   = { keyCode = 46;  modifierFlags = "ctrl+option+command"; };
          center     = { keyCode = 8;   modifierFlags = "ctrl+option+command"; };
        }
      '';
      description = ''
        Rectangle keyboard shortcuts. Attribute names are Rectangle action
        identifiers (e.g. `leftHalf`, `rightHalf`, `maximize`). Each value
        specifies a `keyCode` (macOS virtual key code) and a `modifierFlags`
        string naming the modifier combination (e.g. `"ctrl+option+command"`).

        You can determine keycodes using an app like: <https://manytricks.com/keycodes/>
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.rectangle" pkgs lib.platforms.darwin)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."Library/Application Support/Rectangle/RectangleConfig.json" =
      lib.mkIf (cfg.defaults != { } || cfg.shortcuts != { })
        {
          source = jsonFormat.generate "RectangleConfig.json" {
            bundleId = "com.knollsoft.Rectangle";
            inherit (cfg) defaults;
            shortcuts = lib.mapAttrs (
              _: s:
              s
              // {
                modifierFlags = modifierFlagsMap.${s.modifierFlags};
              }
            ) cfg.shortcuts;
          };
        };
  };
}
