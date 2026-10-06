{
  config,
  lib,
  options,
  realPkgs,
  ...
}:
{
  imports = [
    {
      services.mpdris2.settings = {
        Connection.port = lib.mkDefault 6601;
        Bling.notify = lib.mkDefault false;
        Notify.timeout = lib.mkDefault 1000;
      };
      services.mpdris2.settings.Notify.urgency = 1;
    }
    {
      services.mpdris2.settings.Notify.timeout = lib.mkForce 5000;
      services.mpdris2.settings.Notify.summary = "%artist% - %title%";
      services.mpdris2.settings.Library.cover_regex = "^(album|cover).*$";
    }
  ];

  services.mpdris2 = {
    enable = true;
    notifications = true;
    multimediaKeys = true;
    mpd = {
      musicDirectory = "/home/hm-user/music";
      host = "legacy-host";
      port = 42;
    };
  };

  assertions = [
    {
      assertion = config.services.mpdris2.mpd.port == 6601;
      message = "Legacy reads must reflect the canonical setting.";
    }
  ];

  test.asserts.warnings.expected = [
    "The option `services.mpdris2.mpd.musicDirectory' defined in ${lib.showFiles options.services.mpdris2.mpd.musicDirectory.files} has been changed to `services.mpdris2.settings.Library.music_dir' that has a different type. Please read `services.mpdris2.settings.Library.music_dir' documentation and update your configuration accordingly."
    "The option `services.mpdris2.mpd.port' defined in ${lib.showFiles options.services.mpdris2.mpd.port.files} has been renamed to `services.mpdris2.settings.Connection.port'."
    "The option `services.mpdris2.mpd.host' defined in ${lib.showFiles options.services.mpdris2.mpd.host.files} has been renamed to `services.mpdris2.settings.Connection.host'."
    "The option `services.mpdris2.multimediaKeys' defined in ${lib.showFiles options.services.mpdris2.multimediaKeys.files} has been renamed to `services.mpdris2.settings.Bling.mmkeys'."
    "The option `services.mpdris2.notifications' defined in ${lib.showFiles options.services.mpdris2.notifications.files} has been renamed to `services.mpdris2.settings.Bling.notify'."
  ];

  nmt.script = ''
    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileContent "$configFile" ${./settings.config}
    ${realPkgs.python3}/bin/python - "$TESTED/$configFile" <<'PYTHON'
    import configparser
    import sys
    settings = configparser.ConfigParser()
    with open(sys.argv[1]) as config_file:
        settings.read_file(config_file)
    assert settings.getint("Notify", "timeout") == 5000
    assert settings.getint("Notify", "urgency") == 1
    assert settings.get("Notify", "summary", raw=True) == "%artist% - %title%"
    assert not settings.getboolean("Bling", "notify")
    PYTHON
  '';
}
