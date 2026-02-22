{
  programs.claude-code = {
    enable = true;
    settings = {
      theme = "dark";
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.claude/output-styles
  '';
}
