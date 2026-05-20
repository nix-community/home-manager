{
  pkgs,
  lib,
  options,
  ...
}:

{
  programs.gemini-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "gemini-cli" "";
    policies = {
      "my-rules" = {
        rule = [
          {
            toolName = "run_shell_command";
            commandPrefix = "git ";
            decision = "ask_user";
            priority = 100;
          }
        ];
      };
      "other-rules" = ./other-rules.toml;
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.gemini-cli' defined in ${lib.showFiles options.programs.gemini-cli.files} has been renamed to `programs.antigravity-cli'."
  ];

  nmt.script = ''
    assertFileExists home-files/.gemini/policies/my-rules.toml
    assertFileRegex home-files/.gemini/policies/my-rules.toml \
      'toolName = "run_shell_command"'
    assertFileRegex home-files/.gemini/policies/my-rules.toml \
      'commandPrefix = "git "'

    assertFileExists home-files/.gemini/policies/other-rules.toml
    assertFileRegex home-files/.gemini/policies/other-rules.toml \
      'toolName = "run_shell_command"'
    assertFileRegex home-files/.gemini/policies/other-rules.toml \
      'commandPrefix = "nix "'
  '';
}
