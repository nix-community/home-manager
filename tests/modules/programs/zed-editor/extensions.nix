{ pkgs, ... }:

let
  expectedContent = pkgs.writeText "expected.json" ''
    {
      "auto_install_extensions": {
        "swift": true,
        "html": true,
        "xy-zed": true
      }
    }
  '';
in
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "swift" "html" "xy-zed" ];
    package = pkgs.writeScriptBin "zed" "" // { pname = "zed-editor"; };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/zed/settings.json"
    assertFileContents "home-files/.config/zed/settings.json" "${expectedContent}"
  '';
}

