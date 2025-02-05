# Test custom keymap functionality
{ config, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userSettings = {
      theme = "XY-Zed";
      features = { copilot = false; };
      vim_mode = false;
      ui_font_size = 16;
      buffer_font_size = 16;
    };
  };

  nmt.script = let
    expectedContent = builtins.toFile "expected.json" ''
      {
        "buffer_font_size": 16,
        "features": {
          "copilot": false
        },
        "theme": "XY-Zed",
        "ui_font_size": 16,
        "vim_mode": false
      }
    '';

    settingsPath = ".config/zed/settings.json";
  in ''
    assertFileExists "home-files/${settingsPath}"
    assertFileContent "home-files/${settingsPath}" "${expectedContent}"
  '';
}
