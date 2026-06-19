{
  config,
  lib,
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

    in
    config.lib.test.runMutableConfigTest {
      files.${settingsPath} = preexistingSettings;
      expected.${settingsPath} = expectedContent;
    };
}
