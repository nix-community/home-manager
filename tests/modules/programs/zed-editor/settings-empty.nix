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
