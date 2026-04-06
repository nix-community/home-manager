{
  programs.opencode = {
    enable = true;
    settings = {
      model = "anthropic/claude-sonnet-4-5";
      default_agent = "build";
    };
    tui = {
      theme = "opencode";
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileExists home-files/.config/opencode/tui.json
    assertFileContent home-files/.config/opencode/tui.json \
      ${./tui-with-settings-tui.json}
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./tui-with-settings-config.json}
  '';
}
