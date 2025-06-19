{ pkgs, ... }:
let
  # This would normally not be a file in the store for security reasons.
  testPasswordFile = pkgs.writeText "test-password-file" "password";
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
    sync = {
      autoSync = true;
      syncMedia = true;
      autoSyncMediaMinutes = 15;
      networkTimeout = 60;
      url = "http://example.com/anki-sync/";
      username = "lovelearning@email.com";
      passwordFile = testPasswordFile;
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
