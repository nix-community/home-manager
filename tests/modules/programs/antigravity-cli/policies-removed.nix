_:

{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    policies."my-rules" = {
      rule = [
        {
          toolName = "run_shell_command";
          commandPrefix = "git ";
          decision = "ask_user";
          priority = 100;
        }
      ];
    };
  };

  test.asserts.assertions.expected = [
    ''
      `programs.antigravity-cli.policies` is only supported when
      `programs.antigravity-cli.package` is a `gemini-cli` package.
      Antigravity CLI configures permissions in
      `programs.antigravity-cli.settings.permissions` or
      `programs.antigravity-cli.permissions`.
    ''
  ];
}
