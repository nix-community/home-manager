# allows configuring keybindings
# these are parsed by the parent module (for now)
{
  appName,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;

  keybindingType = types.submodule {
    freeformType = types.json;
    options = {
      key = mkOption {
        type = types.str;
        example = "ctrl+c";
        description = "The key or key-combination to bind.";
      };

      command = mkOption {
        type = types.str;
        example = "editor.action.clipboardCopyAction";
        description = "The VS Code command to execute.";
      };

      when = mkOption {
        type = types.nullOr (types.str);
        default = null;
        example = "textInputFocus";
        description = "Optional context filter.";
      };

      # https://code.visualstudio.com/docs/getstarted/keybindings#_command-arguments
      args = mkOption {
        type = with types; nullOr json;
        default = null;
        example = {
          direction = "up";
        };
        description = "Optional arguments for a command.";
      };
    };
  };
in
{

  _class = "homeManager.vscodeProfile";

  options = {

    keybindings = mkOption {
      type = with types; either path (listOf keybindingType);
      default = [ ];
      example = [
        {
          key = "ctrl+c";
          command = "editor.action.clipboardCopyAction";
          when = "textInputFocus";
        }
      ];
      description = ''
        Keybindings written to ${appName}'s
        {file}`keybindings.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

  };

}
