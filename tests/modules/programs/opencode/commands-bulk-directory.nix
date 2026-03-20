{
  programs.opencode = {
    enable = true;
    commands = ./commands-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/command/changelog.md
    assertFileExists home-files/.config/opencode/command/commit.md
    assertFileContent home-files/.config/opencode/command/changelog.md \
      ${./commands-bulk/changelog.md}
    assertFileContent home-files/.config/opencode/command/commit.md \
      ${./commands-bulk/commit.md}
  '';
}
