{
  programs.cursor-agent = {
    enable = true;
    package = null;

    commands = {
      commit = ''
        Based on the current changes, create a single atomic git commit
        with a descriptive message following conventional commits.
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.cursor/commands/commit.md
    assertFileContent home-files/.cursor/commands/commit.md \
      ${./expected-commit-command.md}
  '';
}
