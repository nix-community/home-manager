# Test custom keymap functionality
{ pkgs, ... }:

let
  settings = {
    theme = "XY-Zed";
    features = { copilot = false; };
    vim_mode = false;
    ui_font_size = 16;
    buffer_font_size = 16;
  };

  expectedContent = pkgs.writeText "expected.json" ''
    {
      "theme": "XY-Zed",
      "features": {
        "copilot": false
      },
      "vim_mode": false,
      "ui_font_size": 16,
      "buffer_font_size": 16,
    }
  '';

  settingsPath = ".config/zed/settings.json";
in {
  programs.zed-editor = {
    enable = true;
    userSettings = settings;
    package = pkgs.writeScriptBin "zed" "" // { pname = "zed-editor"; };
  };

  nmt.script = ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedContent}"
  '';
}
