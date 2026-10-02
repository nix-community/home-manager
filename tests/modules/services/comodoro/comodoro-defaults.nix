{
  services.comodoro.enable = true;

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/comodoro.service)
    assertFileContent "$serviceFile" ${./expected-defaults.service}
  '';
}
