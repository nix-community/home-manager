{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs) userDirectory;

  forkConfig = forkInputs // {
    profiles = {
      default = { };
      work = { };
    };
  };

  mcpDirectory = if forkInputs.package.pname == "cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nmt.script = ''
      # default profile: no files
      #
      assertPathNotExists "home-files/${userDirectory}/keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-keybindings.json"

      assertPathNotExists "home-files/${mcpDirectory}/mcp.json"
      assertPathNotExists "home-files/${mcpDirectory}/.immutable-mcp.json"

      assertPathNotExists "home-files/${userDirectory}/settings.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-settings.json"

      assertPathNotExists "home-files/${userDirectory}/tasks.json"
      assertPathNotExists "home-files/${userDirectory}/.immutable-tasks.json"

      assertPathNotExists "home-files/${userDirectory}/snippets/global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-global.code-snippets"

      assertPathNotExists "home-files/${userDirectory}/snippets/elixir.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-elixir.json"

      assertPathNotExists "home-files/${userDirectory}/snippets/haskell.json"
      assertPathNotExists "home-files/${userDirectory}/snippets/.immutable-haskell.json"

      # work profile: no files
      #
      assertPathNotExists "home-files/${userDirectory}/profiles/work/keybindings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-keybindings.json"

      assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
      assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"

      assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/settings.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-settings.json"

      assertPathNotExists "home-files/${userDirectory}/profiles/work/tasks.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/.immutable-tasks.json"

      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/global.code-snippets"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-global.code-snippets"

      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/elixir.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-elixir.json"

      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/haskell.json"
      assertPathNotExists "home-files/${userDirectory}/profiles/work/snippets/.immutable-haskell.json"
    '';
  };
}
