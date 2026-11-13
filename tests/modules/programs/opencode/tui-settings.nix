{
  imports = [ ./opencode-stubs.nix ];

  programs.opencode = {
    enable = true;
    tui = {
      theme = "tokyonight";
      keybinds.leader = "alt+b";
      scroll_speed = 3;
    };
    validateFiles.tui = true;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/tui.json
    assertFileContent home-files/.config/opencode/tui.json \
      ${./tui.json}
  '';
}
