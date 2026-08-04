{ config, ... }:
{
  programs.crush = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      models.large = {
        model = "claude-sonnet-4-20250514";
        provider = "anthropic";
      };

      providers.deepseek = {
        type = "openai-compat";
        base_url = "https://api.deepseek.com/v1";
        api_key = "$(cat /run/secrets/deepseek-api-key)";
        models = [
          {
            id = "deepseek-chat";
            name = "Deepseek V3";
            context_window = 64000;
          }
        ];
      };

      lsp = {
        nix.command = "nil";
        go = {
          command = "gopls";
          env.GOTOOLCHAIN = "go1.24.5";
        };
      };

      mcp.filesystem = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
      };

      options = {
        disabled_tools = [ "sourcegraph" ];
        initialize_as = "AGENTS.md";
      };

      permissions.allowed_tools = [ "view" ];
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/crush/crush.json ${./crush.json}
  '';
}
