{
  home.stateVersion = "26.11";
  home.preferXdgDirectories = true;

  programs.claude-code = {
    enable = true;
    settings.theme = "dark";
    context = "# XDG context";
  };

  nmt.script = ''
    assertPathNotExists home-files/.claude

    assertFileExists home-files/.config/claude/settings.json
    assertFileExists home-files/.config/claude/CLAUDE.md

    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileRegex home-path/etc/profile.d/hm-session-vars.sh \
      'export CLAUDE_CONFIG_DIR="/home/hm-user/.config/claude"'
  '';
}
