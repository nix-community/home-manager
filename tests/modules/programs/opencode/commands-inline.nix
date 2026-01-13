{
  programs.opencode = {
    enable = true;
    commands = {
      changelog = ''
        # Update Changelog Command

        Update CHANGELOG.md with a new entry for the specified version.
        Usage: /changelog [version] [change-type] [message]
      '';
      commit = ''
        # Commit Command

        Create a git commit with proper message formatting.
        Usage: /commit [message]
      '';
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/command/changelog.md
    assertFileExists home-files/.config/opencode/command/commit.md
    assertFileContent home-files/.config/opencode/command/changelog.md \
      ${./changelog-command.md}
    assertFileContent home-files/.config/opencode/command/commit.md \
      ${./commit-command.md}
  '';
}
