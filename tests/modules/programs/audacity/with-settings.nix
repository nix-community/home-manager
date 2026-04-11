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
    settings = {
      AudioIO = {
        DefaultSampleRate = "44100";
        SWPlaythrough = "0";
      };
      GUI = {
        ShowSplashScreen = "0";
        Theme = "classic";
      };
    };
  };

  nmt.script = ''
    configFile="${configDir}/audacity.cfg"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${builtins.toFile "expected" ''
      [AudioIO]
      DefaultSampleRate=44100
      SWPlaythrough=0

      [GUI]
      ShowSplashScreen=0
      Theme=classic
    ''}
  '';
}
