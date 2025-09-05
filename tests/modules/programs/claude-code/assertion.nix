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
  };

  test.asserts.assertions.expected = [
    "`programs.claude-code.package` cannot be null when `mcpServers` is configured"
  ];
}
