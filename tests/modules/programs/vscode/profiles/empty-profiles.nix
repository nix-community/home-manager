{
  package,
  packageName ? package.pname,
  ...
}@forkInputs:
{
  config,
  lib,
  pkgs,
  ...
}@inputs:
let
  helpers = import ../test-helpers.nix (forkInputs // inputs);

  inherit (helpers) userDirectory;

  forkConfig = {
    inherit (forkInputs) package packageName;

    enable = true;

    profiles = {
      default = { };
      work = { };
    };
  };
in
{
  config = lib.setAttrByPath [ "programs" package.pname ] forkConfig // {
    nmt.script = ''
      echo "pname: ${package.pname}, packageName: ${packageName}"
      echo "userDirectory: ${userDirectory}"

      # default profile: no files
      #
      assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/mcp.json"
      assertPathNotExists "home-files/${userDirectory}/settings.json"
      assertPathNotExists "home-files/${userDirectory}/tasks.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/global.code-snippets"

      # work profile: no files
      #
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-mcp.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/mcp.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/tasks.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
    '';
  };
}
