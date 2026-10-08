{
  programs.mcp = {
    enable = true;
    servers = {
      invalid = {
        command = "echo";
        args = [ "test" ];
        enabled = true;
        disabled = true;
      };
    };
  };

  test.asserts.assertions.expected = [
    ''
      programs.mcp.servers.invalid: `enabled` and `disabled` are set to incompatible values.
    ''
  ];
}
