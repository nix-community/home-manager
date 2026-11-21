{
  services.comodoro = {
    enable = true;
    account = "pomodoro";
    transports = [
      "socket"
      "tcp"
    ];
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/comodoro.service)
    assertFileContent "$serviceFile" ${./expected.service}
  '';
}
