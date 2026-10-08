{
  programs.pi-coding-agent = {
    enable = true;
    context = ''
      # Global Pi Context

      Always use TypeScript strict mode.
      Follow the project's existing code style.
    '';
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/AGENTS.md
    assertFileContent home-files/.pi/agent/AGENTS.md \
      ${./context-inline.md}
  '';
}
