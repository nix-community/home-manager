# Test custom keymap functionality
{
  config,
  lib,
  pkgs,
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
      activationScript = pkgs.writeScript "activation" config.home.activation.zedSettingsActivation.data;
    in
    ''
      export HOME=$TMPDIR/hm-user

      # Simulate preexisting settings
      mkdir -p $HOME/.config/zed
      cat ${preexistingSettings} > $HOME/${settingsPath}

      # Run the activation script
      substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
      chmod +x $TMPDIR/activate
      $TMPDIR/activate

      # Validate the merged settings
      assertFileExists "$HOME/${settingsPath}"
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"

      # Test idempotency
      $TMPDIR/activate
      assertFileExists "$HOME/${settingsPath}"
      assertFileContent "$HOME/${settingsPath}" "${expectedContent}"
    '';
}
