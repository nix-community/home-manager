{ pkgs, ... }:
{
  programs.anki = {
    enable = true;
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
    '';
}
