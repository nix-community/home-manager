{
  home.preferXdgDirectories = true;
  programs.codex = {
    enable = true;
    custom-instructions = ''
      - Always respond with emojis
      - Only use git commands when explicitly requested
    '';
  };
  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export CODEX_HOME="/home/hm-user/.config/codex"'
    assertFileExists home-files/.config/codex/AGENTS.md
    assertFileContent home-files/.config/codex/AGENTS.md \
      ${./AGENTS.md}
  '';
}
