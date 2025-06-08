{
  programs.codex = {
    enable = true;
    custom-instructions = ''
      - Always respond with emojis
      - Only use git commands when explicitly requested
    '';
  };
  nmt.script = ''
    assertFileExists home-files/.codex/AGENTS.md
    assertFileContent home-files/.codex/AGENTS.md \
      ${./custom-instructions.md}
  '';
}
