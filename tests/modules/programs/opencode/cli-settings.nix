{
  imports = [ ./opencode-v2-stubs.nix ];

  programs.opencode = {
    enable = true;
    settings = {
      model = "anthropic/claude-sonnet-4-5";
      autoshare = false;
      autoupdate = true;
    };
    cli = {
      theme = {
        name = "tokyonight";
        mode = "system";
      };
      scroll.speed = 3;
      tabs.mode = "off";
      keybinds.leader = "alt+b";
    };
    validateFiles = {
      config = true;
      cli = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./opencode.json}
    assertFileExists home-files/.config/opencode/cli.json
    assertFileContent home-files/.config/opencode/cli.json \
      ${./cli.json}
    assertPathNotExists home-files/.config/opencode/tui.json
  '';
}
