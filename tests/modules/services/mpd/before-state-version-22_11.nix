{
  services.mpd = {
    enable = true;
    extraArgs = [ "--verbose" ];
  };

  home.stateVersion = "18.09";

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/mpd.service)
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    confFile=$(grep -o \
        '/nix/store/.*-mpd.conf' \
        $TESTED/home-files/.config/systemd/user/mpd.service)

    assertFileContains \
      "$confFile" \
      'music_directory     "/home/hm-user/music"'
  '';
}
