{ pkgs, ... }:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support/audacity"
    else
      "home-files/.config/audacity";
in
{
  programs.audacity = {
    enable = true;
    pluginSettings = {
      Normalize = {
        ApplyGain = "0";
        PeakLevel = "-1";
      };
    };
  };

  nmt.script = ''
    settingsFile="${configDir}/pluginsettings.cfg"
    assertFileExists "$settingsFile"
    assertFileContent "$settingsFile" ${builtins.toFile "expected" ''
      [Normalize]
      ApplyGain=0
      PeakLevel=-1
    ''}
  '';
}
