{ config, lib, pkgs, ... }:

with lib;

{
  services.mpd = {
    enable = true;
    extraArgs = [ "--verbose" ];
  };

  xdg.userDirs.enable = true;

  home.stateVersion = "22.11";

  test.stubs.mpd = { };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/mpd.service)
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    confFile=$(grep -o \
        '/nix/store/.*-mpd.conf' \
        $TESTED/home-files/.config/systemd/user/mpd.service)
    assertFileContent "$confFile" ${./xdg-music-dir.conf}
  '';
}
