{
  config,
  lib,
  ...
}:
let
  activation = config.home.activation.antigravitySettings;
in
{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    mutableSettings = true;
    settings = {
      colorScheme = "tokyo night";
    };
    permissions.allow = [ "command(git)" ];
    mcpServers.filesystem = {
      command = "fs";
      args = [ ];
      enabled = true;
    };
  };

  assertions = [
    {
      assertion = lib.hasInfix "display_path=${lib.escapeShellArg "/home/hm-user/.gemini/antigravity-cli/settings.json"}\n" config.home.activation.antigravitySettings.data;
      message = "Antigravity settings must merge into the configured destination.";
    }
    {
      assertion = lib.hasInfix "display_path=${lib.escapeShellArg "/home/hm-user/.gemini/config/mcp_config.json"}\n" config.home.activation.antigravitySettings.data;
      message = "Antigravity MCP settings must merge into the configured destination.";
    }
    {
      assertion = !(config.home.file ? ".gemini/config/mcp_config.json");
      message = "Mutable Antigravity MCP settings must not be owned by home.file.";
    }
    {
      assertion = !(config.home.file ? ".gemini/antigravity-cli/settings.json");
      message = "Mutable Antigravity settings must not be owned by home.file.";
    }
    {
      assertion = activation.after == [ "linkGeneration" ];
      message = "Antigravity settings must merge after linkGeneration.";
    }
  ];
  nmt.script = ''
    assertPathNotExists home-files/.gemini/antigravity-cli/settings.json
    assertPathNotExists home-files/.gemini/config/mcp_config.json
    settings="$(grep -m1 -o '/nix/store/[^ ]*-antigravity-cli-settings.json' "$TESTED/activate")" \
      || fail "Missing antigravity-cli-settings.json input"
    assertFileContent "$settings" ${./mutable-input.json}
    mcp="$(grep -m1 -o '/nix/store/[^ ]*-antigravity-cli-mcp-config.json' "$TESTED/activate")" \
      || fail "Missing antigravity-cli-mcp-config.json input"
    assertFileContent "$mcp" ${./mutable-mcp-input.json}
  '';
}
