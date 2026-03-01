{
  services.mpd-mpris = {
    enable = true;
    settings = {
      host = "example.com";
      port = 1234;
      instance-name = "test-instance";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-with-instance-name.service}
  '';
}
