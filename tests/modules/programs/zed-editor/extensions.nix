{ config, lib, ... }:

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

  home.homeDirectory = lib.mkForce "/build/hm-user";

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
