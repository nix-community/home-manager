{ pkgs, ... }:

{
  programs.streamlink = {
    enable = true;
    settings = {
      player = "mpv";
      player-args = "--cache 2048";
      player-no-close = true;
      http-header = [
        "User-Agent=Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"
        "Accept-Language=en-US"
      ];
    };
  };

  test.stubs.streamlink = { };

  nmt.script = let
    streamlinkConfig = if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/streamlink/config"
    else
      ".config/streamlink/config";
  in ''
    assertFileExists "home-files/${streamlinkConfig}"
    assertFileContent "home-files/${streamlinkConfig}" ${./config}
  '';
}
