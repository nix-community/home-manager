# Test custom keymap functionality
{ config, lib, ... }:

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

  home.homeDirectory = lib.mkForce "/build/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "preexisting.json" ''
        {
          "theme": "Default",
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
    ''
      export HOME=${config.home.homeDirectory}

      # Simulate preexisting settings
      mkdir -p $HOME/.config/zed
      cat ${preexistingSettings} > $HOME/${settingsPath}

      # Run the activation script
      ${config.home.activation.zedSettingsActivation.data}

      # Validate the merged settings
      assertFileExists "$HOME/${settingsPath}"
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"

      # Test idempotency
      ${config.home.activation.zedSettingsActivation.data}
      assertFileExists "$HOME/${settingsPath}"
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"
    '';
}
