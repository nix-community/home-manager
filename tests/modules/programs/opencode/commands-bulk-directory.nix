{
  programs.opencode = {
    enable = true;
    commands = ./commands-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/commands/changelog.md
    assertFileExists home-files/.config/opencode/commands/commit.md
    assertFileContent home-files/.config/opencode/commands/changelog.md \
      ${./commands-bulk/changelog.md}
    assertFileContent home-files/.config/opencode/commands/commit.md \
      ${./commands-bulk/commit.md}
  '';
}
