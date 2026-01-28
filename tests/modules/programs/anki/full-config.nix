{ pkgs, ... }:
let
  # This would normally not be a file in the store for security reasons.
  fooKeyFile = pkgs.writeText "foo-key-file" "a-sync-key";
  barKeyFile = pkgs.writeText "bar-key-file" "a-sync-key";
in
{
  programs.anki = {
    enable = true;
    addons = [ pkgs.ankiAddons.passfail2 ];
    answerKeys = [
      {
        ease = 1;
        key = "left";
      }
      {
        ease = 2;
        key = "up";
      }
    ];
    hideBottomBar = true;
    hideBottomBarMode = "fullscreen";
    hideTopBar = false;
    hideTopBarMode = "always";
    language = "en_US";
    legacyImportExport = false;
    minimalistMode = true;
    reduceMotion = true;
    spacebarRatesCard = true;
    style = "native";
    theme = "dark";
    uiScale = 1.0;
    videoDriver = "opengl";
    profiles = {
      foo = {
        default = true;
        sync = {
          autoSync = true;
          syncMedia = true;
          autoSyncMediaMinutes = 15;
          networkTimeout = 60;
          url = "http://foo.com/anki-sync/";
          username = "foo@email.com";
          keyFile = fooKeyFile;
        };
      };
      bar = {
        sync = {
          autoSync = false;
          syncMedia = false;
          autoSyncMediaMinutes = 30;
          networkTimeout = 120;
          url = "http://foo.com/anki-sync/";
          username = "bar@email.com";
          keyFile = barKeyFile;
        };
      };
    };
  };

  nmt.script =
    let
      ankiBaseDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/Anki2"
        else
          "home-files/.local/share/Anki2";
    in
    ''
      assertFileExists "${ankiBaseDir}/prefs21.db"

      assertFileExists "${ankiBaseDir}/gldriver6"
    '';
}
