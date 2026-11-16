{
  home.stateVersion = "26.05";
  home.preferXdgDirectories = true;

  programs.claude-code = {
    enable = true;
    settings.theme = "dark";
    context = "# Legacy context";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/claude

    assertFileExists home-files/.claude/settings.json
    assertFileExists home-files/.claude/CLAUDE.md

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      'CLAUDE_CONFIG_DIR'
  '';
}
