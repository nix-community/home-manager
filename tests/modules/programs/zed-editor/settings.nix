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
      preexistingSettings = builtins.toFile "preexisting.json" ''
        {
          // I chose this theme interactively
          "theme": "Default",

          /* I change AI settings interactively */
          "features": {
            "copilot": true,
            "ai_assist": true
          },
          "vim_mode": true
        }
      '';

      expectedContent = builtins.toFile "expected.json" ''
        {
          "theme": "XY-Zed",
          "features": {
            "copilot": false,
            "ai_assist": true
          },
          "vim_mode": false,
          "buffer_font_size": 16,
          "ui_font_size": 16
        }
      '';

      settingsPath = ".config/zed/settings.json";
    in
    config.lib.test.runMutableConfigTest {
      files.${settingsPath} = preexistingSettings;
      expected.${settingsPath} = expectedContent;
      setup = ''
        chmod 600 "$HOME/${settingsPath}"
      '';
      assertions = ''
        test "$(stat -c '%a' "$HOME/${settingsPath}")" = 600
      '';
    };
}
