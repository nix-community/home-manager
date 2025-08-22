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

    # assert fail: cannot set text and source at the same time.
    memory = {
      text = "Some text content";
      source = ./expected-memory.md;
    };

    # assert fail: cannot set agents and agentsDir at the same time.
    agents = {
      test-agent = "test content";
    };
    agentsDir = ./agents;
  };

  test.asserts.assertions.expected = [
    "`programs.claude-code.package` cannot be null when `mcpServers` is configured"
    "Cannot specify both `programs.claude-code.memory.text` and `programs.claude-code.memory.source`"
    "Cannot specify both `programs.claude-code.agents` and `programs.claude-code.agentsDir`"
  ];
}
