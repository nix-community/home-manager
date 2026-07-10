{ config, ... }:

{
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.75";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };

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
    "Managed Claude Code MCP, LSP, and plugins require `programs.claude-code.package` version 2.1.76 or later"
    "Cannot specify both `programs.claude-code.agents` and `programs.claude-code.agentsDir`"
    "Cannot specify both `programs.claude-code.commands` and `programs.claude-code.commandsDir`"
    "Cannot specify both `programs.claude-code.hooks` and `programs.claude-code.hooksDir`"
  ];
}
