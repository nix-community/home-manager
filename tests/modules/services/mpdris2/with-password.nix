{ lib, options, ... }:
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

  test.asserts.warnings.expected = [
    "The option `services.mpdris2.mpd.password' defined in ${lib.showFiles options.services.mpdris2.mpd.password.files} has been renamed to `services.mpdris2.settings.Connection.password'."
    "The option `services.mpdris2.mpd.port' defined in ${lib.showFiles options.services.mpdris2.mpd.port.files} has been renamed to `services.mpdris2.settings.Connection.port'."
    "The option `services.mpdris2.mpd.host' defined in ${lib.showFiles options.services.mpdris2.mpd.host.files} has been renamed to `services.mpdris2.settings.Connection.host'."
  ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpdris2.service
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileContent "$configFile" ${./with-password.config}
  '';
}
