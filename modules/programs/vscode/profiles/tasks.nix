# allows configuring tasks
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

    userTasks = mkOption {
      type = with types; either path json;
      default = { };
      example = {
        version = "2.0.0";
        tasks = [
          {
            type = "shell";
            label = "Hello task";
            command = "hello";
          }
        ];
      };
      description = ''
        Configuration written to ${appName}'s
        {file}`tasks.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

  };

}
