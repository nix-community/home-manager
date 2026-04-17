{ lib, options, ... }:

{
  programs.claude-code = {
    enable = true;
    memory.text = ''
      # Project Memory

      This configuration still uses the legacy memory.text option.
    '';
  };

  test.asserts.warnings.expected = [
    "The option `programs.claude-code.memory.text' defined in ${lib.showFiles options.programs.claude-code.memory.text.files} has been changed to `programs.claude-code.context' that has a different type. Please read `programs.claude-code.context' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    assertFileExists home-files/.claude/CLAUDE.md
    assertFileContent home-files/.claude/CLAUDE.md \
      ${builtins.toFile "expected-legacy-memory-text.md" ''
        # Project Memory

        This configuration still uses the legacy memory.text option.
      ''}
  '';
}
