{ ... }:

{
  services.pasystray = {
    enable = true;
    extraOptions = [ "-g" ];
  };

  test.stubs = {
    pasystray = { };
    paprefs = { };
    pavucontrol = { };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/pasystray.service)
    assertFileContent "$serviceFile" ${./expected.service}
  '';
}
