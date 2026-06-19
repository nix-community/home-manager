# Test custom keymap functionality
{
  config,
  lib,
  ...
}:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    userSettings = {
      theme = "XY-Zed";
      features = {
        copilot = false;
      };
      vim_mode = false;
      ui_font_size = 16;
      buffer_font_size = 16;
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      # For some reason, the preexisting settings is an empty file
      preexistingSettings = builtins.toFile "preexisting.json" "";

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
    in
    config.lib.test.runMutableConfigTest {
      files.${settingsPath} = preexistingSettings;
      expected.${settingsPath} = expectedContent;
    };
}
