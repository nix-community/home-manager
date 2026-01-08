{ forkInputs, lib, ... }@inputs:
let
  inherit (import ../test-helpers.nix inputs)
    isMutableProfile
    mcpJsonObject
    mcpJsonPath
    userDirectory
    ;

  forkConfig = forkInputs // {
    profiles = {
      default.mcp = mcpJsonPath;
      work.mcp = mcpJsonObject;
    };
  };

  mcpDirectory = if forkInputs.package.pname == "cursor" then ".cursor" else userDirectory;
in
{
  config = lib.setAttrByPath [ "programs" forkInputs.moduleName ] forkConfig // {
    nmt.script = ''
      # mutable profiles create immutable nix store files and mutable copies on activation
      # immutable profiles create immutable nix store files linked to the files themselves
      #
      if [[ -n "${toString isMutableProfile}" ]]; then
        assertLinkExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertFileExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertFileContent "home-files/${mcpDirectory}/.immutable-mcp.json" "${mcpJsonPath}"

        if [[ "${forkInputs.package.pname}" == "cursor" ]]; then
          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
        else
          assertLinkExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          assertFileExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          assertFileContent "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json" "${mcpJsonPath}"

          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
        fi

        # mutable copies are created only during activation
        #
        assertPathNotExists "home-files/${mcpDirectory}/mcp.json"
        assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
      else
        assertLinkExists "home-files/${mcpDirectory}/mcp.json"
        assertFileExists "home-files/${mcpDirectory}/mcp.json"
        assertFileContent "home-files/${mcpDirectory}/mcp.json" "${mcpJsonPath}"

        assertPathNotExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"

        if [[ "${forkInputs.package.pname}" == "cursor" ]]; then
            assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
        else
            assertLinkExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
            assertFileExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
            assertFileContent "home-files/${mcpDirectory}/profiles/work/mcp.json" "${mcpJsonPath}"
        fi
      fi;
    '';
  };
}
