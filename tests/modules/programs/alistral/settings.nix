{ pkgs, ... }:

{
  programs.alistral = {
    enable = true;
    settings = {
      default_user = "spanish_inquisition";
      listenbrainz_url = "https://api.listenbrainz.org/1/";
      musicbrainz_url = "http://musicbrainz.org/ws/2";
    };
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/alistral"
        else
          ".config/alistral";
    in
    ''
      assertFileExists "home-files/${configDir}/config.json"
      assertFileContent "home-files/${configDir}/config.json" \
        ${./config.json}
    '';
}
