{
  services.mpd-mpris = {
    enable = true;
    settings = {
      network = "tcp";
      host = "example.com";
      port = 1234;
      pwd-file = "/path/to/my_password";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpd-mpris.service
    assertFileContent "$serviceFile" ${./configuration-with-password.service}
  '';
}
