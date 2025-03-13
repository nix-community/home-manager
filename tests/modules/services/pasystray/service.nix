{
  services.pasystray = {
    enable = true;
    extraOptions = [ "-g" ];
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/pasystray.service)
    assertFileContent "$serviceFile" ${./expected.service}
  '';
}
