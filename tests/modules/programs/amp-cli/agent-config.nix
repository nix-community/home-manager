{
  programs.amp-cli = {
    enable = true;

    agentConfig = ''
      # Personal Preferences

      - Always use conventional commits
      - Prefer TypeScript over JavaScript
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/amp/AGENTS.md
    assertFileContent home-files/.config/amp/AGENTS.md ${./expected-agents.md}
  '';
}
