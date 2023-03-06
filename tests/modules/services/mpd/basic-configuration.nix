{ config, lib, pkgs, ... }:

with lib;

{
  services.mpd = {
    enable = true;
    musicDirectory = "/my/music/dir";
    extraArgs = [ "--verbose" ];
  };

  home.stateVersion = "22.11";

  test.stubs.mpd = { };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/mpd.service)
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    confFile=$(grep -o \
        '/nix/store/.*-mpd.conf' \
        $TESTED/home-files/.config/systemd/user/mpd.service)
    assertFileContent "$confFile" ${./basic-configuration.conf}
  '';
}
