# options to modify the user settings
# these are parsed by the parent module (for now)
{
  appName,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
in
{

  _class = "homeManager.vscodeProfile";

  options = {

    userSettings = mkOption {
      type = with types; either path json;
      default = { };
      example = {
        "files.autoSave" = "off";
        "[nix]"."editor.tabSize" = 2;
      };
      description = ''
        Configuration written to ${appName}'s
        {file}`settings.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

  };

}
