{
  programs.opencode = {
    enable = true;
    settings = {
      theme = "opencode";
      model = "anthropic/claude-sonnet-4-20250514";
      autoshare = false;
      autoupdate = true;
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/config.json
    assertFileContent home-files/.config/opencode/config.json \
      ${./config.json}
  '';
}
