{
  services.mpd-mpris = {
    enable = true;
    mpd = {
      network = "tcp";
      host = "example.com";
      port = 1234;
      password = "my_password";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-with-password.service}
  '';
}
