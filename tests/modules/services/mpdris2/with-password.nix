{
  services.mpdris2 = {
    enable = true;
    mpd = {
      host = "somehost";
      port = 42;
      password = "foo";
    };
  };

  services.mpd.musicDirectory = "/home/hm-user/music";

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpdris2.service
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileContent "$configFile" ${./with-password.config}
  '';
}
