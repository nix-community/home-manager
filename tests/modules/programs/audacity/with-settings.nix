{
  config,
  lib,
  pkgs,
  ...
}:

let
  activationScript = pkgs.writeScript "activation" config.home.activation.audacitySettings.data;
in
{
  programs.audacity = {
    enable = true;
    settings = {
      globalSection.PrefsVersion = "1.1.0.0";
      sections = {
        AudioIO = {
          DefaultSampleRate = "44100";
          SWPlaythrough = false;
        };
        GUI = {
          ShowSplashScreen = false;
          Theme = "classic";
        };
      };
    };
  };

  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    export HOME=$TMPDIR/hm-user

    substitute ${activationScript} $TMPDIR/activate --subst-var TMPDIR
    chmod +x $TMPDIR/activate
    $TMPDIR/activate

    configFile="$HOME/${
      if pkgs.stdenv.hostPlatform.isDarwin then
        "Library/Application Support/audacity"
      else
        ".config/audacity"
    }/audacity.cfg"

    assertFileExists "$configFile"
    assertFileContent "$configFile" ${builtins.toFile "expected" ''
      PrefsVersion=1.1.0.0

      [AudioIO]
      DefaultSampleRate=44100
      SWPlaythrough=0

      [GUI]
      ShowSplashScreen=0
      Theme=classic
    ''}
  '';
}
