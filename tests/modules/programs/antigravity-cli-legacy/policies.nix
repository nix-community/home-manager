{
  lib,
  options,
  ...
}:

let
  renamedWarning =
    name:
    "The option `programs.gemini-cli.${name}' defined in ${
      lib.showFiles (
        lib.getAttrFromPath [
          "programs"
          "gemini-cli"
          name
          "files"
        ] options
      )
    } has been renamed to `programs.antigravity-cli.${name}'.";
in
{
  test.stubs.gemini-cli = {
    name = "gemini-cli";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin
      touch $out/bin/gemini
    '';
  };

  programs.gemini-cli = {
    enable = true;
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

  test.asserts.warnings.expected = map renamedWarning [
    "policies"
    "enable"
  ];

  nmt.script = ''
    assertFileExists home-path/bin/gemini

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
