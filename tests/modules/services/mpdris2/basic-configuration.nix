{ lib, options, ... }:
{
  services.mpdris2 = {
    enable = true;
    notifications = true;
    multimediaKeys = true;
  };

  services.mpd.musicDirectory = "/home/hm-user/music";

  test.asserts.warnings.expected = [
    "The option `services.mpdris2.multimediaKeys' defined in ${lib.showFiles options.services.mpdris2.multimediaKeys.files} has been renamed to `services.mpdris2.settings.Bling.mmkeys'."
    "The option `services.mpdris2.notifications' defined in ${lib.showFiles options.services.mpdris2.notifications.files} has been renamed to `services.mpdris2.settings.Bling.notify'."
  ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/mpdris2.service
    assertFileContent "$serviceFile" ${./basic-configuration.service}

    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileContent "$configFile" ${./basic-configuration.config}
  '';
}
