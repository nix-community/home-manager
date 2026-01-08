{ forkInputs, lib, ... }@inputs:
let
  helpers = import ../test-helpers.nix inputs;

  inherit (helpers)
    isMutableProfile
    mcpJsonObject
    mcpJsonPath
    mcpServersKey
    userDirectory
    ;

  mcpConfig = {
    enable = true;

    servers = {
      everything = {
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      disabled-server = {
        command = "echo";
        disabled = true;
      };
    };
  };

  forkConfig = forkInputs // {
    profiles = {
      default = {
        enableMcpIntegration = true;
        mcp = mcpJsonObject;
      };
      work = {
        enableMcpIntegration = true;
        mcp = mcpJsonPath;
      };
    };
  };

  mcpIntegrationServersJsonPath = builtins.toFile "${forkInputs.package.pname}-profile-with-global-servers.json.test" ''
    {
      "${mcpServersKey}": {
        "context7": {
          "enabled": true,
          "headers": {
            "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
          },
          "type": "remote",
          "url": "https://mcp.context7.com/mcp"
        },
        "disabled-server": {
          "command": "echo",
          "enabled": false,
          "type": "local"
        },
        "echo": {
          "command": "echo"
        },
        "everything": {
          "args": [
            "-y",
            "@modelcontextprotocol/server-everything"
          ],
          "command": "npx",
          "enabled": true,
          "type": "local"
        }
      }
    }
  '';

  mcpDirectory = if forkInputs.package.pname == "cursor" then ".cursor" else userDirectory;
in
{
  config = ({
    programs.mcp = mcpConfig;
    programs.${forkInputs.moduleName} = forkConfig;
  })
  // {
    nmt.script = ''
      if [[ -n "${toString isMutableProfile}" ]]; then
        # default profile
        #
        assertLinkExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertFileExists "home-files/${mcpDirectory}/.immutable-mcp.json"
        assertFileContent "home-files/${mcpDirectory}/.immutable-mcp.json" ${mcpIntegrationServersJsonPath}

        if [[ "${forkInputs.package.pname}" == "cursor" ]]; then
          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
        else
          assertLinkExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          assertFileExists "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json"
          assertFileContent "home-files/${mcpDirectory}/profiles/work/.immutable-mcp.json" ${mcpIntegrationServersJsonPath}
        fi
      else
        # default profile
        #
        assertLinkExists "home-files/${mcpDirectory}/mcp.json"
        assertFileExists "home-files/${mcpDirectory}/mcp.json"
        assertFileContent "home-files/${mcpDirectory}/mcp.json" ${mcpIntegrationServersJsonPath}

        if [[ "${forkInputs.package.pname}" == "cursor" ]]; then
          assertPathNotExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
        else
          assertLinkExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
          assertFileExists "home-files/${mcpDirectory}/profiles/work/mcp.json"
          assertFileContent "home-files/${mcpDirectory}/profiles/work/mcp.json" ${mcpIntegrationServersJsonPath}
        fi
      fi;
    '';
  };
}
