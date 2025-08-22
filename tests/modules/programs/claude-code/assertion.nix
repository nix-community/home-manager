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
  };

  test.asserts.assertions.expected = [
    "`programs.claude-code.package` cannot be null when `mcpServers` is configured"
    "Cannot specify both `programs.claude-code.memory.text` and `programs.claude-code.memory.source`"
  ];
}
