{ config, lib, pkgs, ... }:

with lib;

{
  services.mpdscribble = {
    enable = true;
    endpoints = {
      "libre.fm" = {
        username = "musicfan1992";
        passwordFile = toString ./password-file;
      };
      "https://music.com/" = {
        username = "musicHATER1000";
        passwordFile = toString ./password-file;
      };
    };
  };

  home.stateVersion = "22.11";

  test.stubs.mpd = { };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/mpdscribble.service)
    assertFileContent "$serviceFile" ${./basic-configuration.service}
  '';
}
