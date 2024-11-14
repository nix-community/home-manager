{ config, ... }:

{
  programs.zed-editor = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    extensions = [ "swift" "html" "xy-zed" ];
  };

  nmt.script = let
    expectedContent = builtins.toFile "expected.json" ''
      {
        "auto_install_extensions": {
          "html": true,
          "swift": true,
          "xy-zed": true
        }
      }
    '';
  in ''
    assertFileExists "home-files/.config/zed/settings.json"
    assertFileContent "home-files/.config/zed/settings.json" "${expectedContent}"
  '';
}
