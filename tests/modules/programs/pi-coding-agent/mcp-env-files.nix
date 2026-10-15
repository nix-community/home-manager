{ pkgs, ... }:

{
  programs.mcp = {
    enable = true;
    servers.shared = {
      command = "shared-server";
      args = [ "--stdio" ];
      env.TOKEN.file = "/run/secrets/shared-token";
    };
  };

  programs.pi-coding-agent = {
    enable = true;
    enableMcpIntegration = true;
    mcpServers.local = {
      command = "local-server";
      args = [ "--stdio" ];
      env = {
        API_URL = "https://example.com";
        TOKEN.file = "/run/secrets/local-token";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.pi/agent/mcp.json
    shared=$(${pkgs.jq}/bin/jq -r '.mcpServers.shared.command' "$TESTED/home-files/.pi/agent/mcp.json")
    local=$(${pkgs.jq}/bin/jq -r '.mcpServers.local.command' "$TESTED/home-files/.pi/agent/mcp.json")
    assertFileRegex "$shared" '/run/secrets/shared-token'
    assertFileRegex "$shared" "exec shared-server --stdio"
    assertFileRegex "$local" '/run/secrets/local-token'
    assertFileRegex "$local" "exec local-server --stdio"
    assertFileRegex home-files/.pi/agent/mcp.json '"API_URL": "https://example.com"'
    assertFileNotRegex home-files/.pi/agent/mcp.json '"file"\|"TOKEN"'
  '';
}
