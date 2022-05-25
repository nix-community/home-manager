{ ... }:

{
  services.mpdris2 = {
    enable = true;
    notifications = true;
    multimediaKeys = true;
  };

  test.stubs.mpdris2 = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpdris2.service
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileContent "$configFile" ${./basic-configuration.config}
  '';
}
