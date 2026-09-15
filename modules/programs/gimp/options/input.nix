{ lib, ... }:
let
  inherit (lib) literalExpression mkOption types;
in
{
  options.programs.gimp = {
    keyboardShortcuts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            modifiers = mkOption {
              type = types.listOf (
                types.enum [
                  "primary"
                  "shift"
                  "alt"
                  "super"
                ]
              );
              default = [ ];
              description = "`primary` is Ctrl on Linux/Windows and Cmd on macOS.";
            };
            key = mkOption {
              type = types.str;
              default = "";
              description = ''
                Key name such as `"c"`, `"Return"`, or `"F1"`.
                Leave empty with no modifiers to unassign the shortcut.
              '';
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          "edit-copy"  = { modifiers = [ "primary" ];         key = "c"; };
          "edit-undo"  = { modifiers = [ "primary" "shift" ]; key = "z"; };
          "file-quit"  = { modifiers = [ "primary" ];         key = "q"; };
          "select-all" = { };
        }
      '';
      description = ''
        Keyboard shortcuts written to {file}`$XDG_CONFIG_HOME/GIMP/<version>/shortcutsrc`.
        An empty attrset `{ }` writes `(action "name")`, unassigning that shortcut.
        Note: GIMP rewrites `shortcutsrc` on exit.
      '';
    };

    controllers = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Whether this controller is active.";
            };
            events = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    stroke = mkOption {
                      type = types.str;
                      description = "Input event identifier, e.g. `\"key-cursor-up\"`.";
                    };
                    action = mkOption {
                      type = types.str;
                      description = "GIMP action path, e.g. `\"tools/gimp-paintbrush\"`.";
                    };
                  };
                }
              );
              default = [ ];
              description = "Stroke → action bindings for this controller.";
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          GimpControllerKeyboard = {
            enabled = true;
            events  = [ { stroke = "key-cursor-up"; action = "tools/gimp-paintbrush"; } ];
          };
          GimpControllerMouse = { enabled = false; events = []; };
        }
      '';
      description = ''
        Input device controllers written to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/controllerrc`.

        Attribute names are GIMP controller type names such as
        `GimpControllerKeyboard`, `GimpControllerMouse`, `GimpControllerWheel`.

        Note: GIMP rewrites `controllerrc` on exit.
      '';
    };

    extraControllerrc = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Raw lines appended after the generated `controllerrc`.
        Use for controller types not expressible via {option}`programs.gimp.controllers`.
      '';
    };
  };
}
