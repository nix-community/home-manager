{
  programs.claude-code = {
    enable = true;
    package = null;

    mcpServers = {
      filesystem = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/tmp"
        ];
      };
    };

    # assert fail: cannot set agents and agentsDir at the same time.
    agents = {
      test-agent = "test content";
    };
    agentsDir = ./agents;

    # assert fail: cannot set commands and commandsDir at the same time.
    commands = {
      test-command = "test content";
    };
    commandsDir = ./commands;

    # assert fail: cannot set hooks and hooksDir at the same time.
    hooks = {
      test-hook = "test content";
    };
    hooksDir = ./hooks;

  };

  test.asserts.assertions.expected = [
    "`programs.claude-code.package` cannot be null when `mcpServers`, `lspServers`, `enableMcpIntegration`, or `plugins` is configured"
    "Cannot specify both `programs.claude-code.agents` and `programs.claude-code.agentsDir`"
    "Cannot specify both `programs.claude-code.commands` and `programs.claude-code.commandsDir`"
    "Cannot specify both `programs.claude-code.hooks` and `programs.claude-code.hooksDir`"
  ];
}
