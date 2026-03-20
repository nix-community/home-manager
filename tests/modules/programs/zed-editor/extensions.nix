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
    extensions = [
      "swift"
      "html"
      "xy-zed"
    ];
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script =
    let
      preexistingSettings = builtins.toFile "preexisting.json" ''
        {
          "auto_install_extensions": {
            "python": true,
            "javascript": true
          }
        }
      '';

      expectedContent = builtins.toFile "expected.json" ''
        {
          "auto_install_extensions": {
            "python": true,
            "javascript": true,
            "html": true,
            "swift": true,
            "xy-zed": true
          }
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
