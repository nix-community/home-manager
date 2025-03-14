{
  services.mpd = {
    enable = true;
    musicDirectory = "/my/music/dir";
    extraArgs = [ "--verbose" ];
    network.startWhenNeeded = true;
  };

  home.stateVersion = "22.11";

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/mpd.service)
    assertFileContent "$serviceFile" ${./start-when-needed.service}

    socketFile=home-files/.config/systemd/user/mpd.socket
    assertFileContent "$socketFile" ${./start-when-needed.socket}

    confFile=$(grep -o \
        '/nix/store/.*-mpd.conf' \
        $TESTED/home-files/.config/systemd/user/mpd.service)
    assertFileContent "$confFile" ${./basic-configuration.conf}
  '';
}
