{
  services.comodoro = {
    enable = true;
    preset = "preset";
    protocols = [ "tcp" ];
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/comodoro.service)
    assertFileContent "$serviceFile" ${./expected.service}
  '';
}
