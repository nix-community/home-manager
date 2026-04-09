{
  config,
  ...
}:
{
  services.syshud = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "syshud";
      outPath = "@syshud@";
    };
    settings = {
      position = "top";
      orientation = "v";
      width = 200;
      height = 67;
      icon-size = 26;
      show-percentage = false;
      margins = "0 0 10 0";
      timeout = 3;
      transition-time = 250;
      listeners = "audio_in,audio_out,backlight,keyboard";
      backlight-path = "/sys/class/backlight/gmux_backlight";
      keyboard-path = "/dev/input/event21";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/syshud.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./syshud-default.service}

    configFile=home-files/.config/sys64/hud/config.conf
    assertFileExists $configFile
    assertFileContent $configFile ${./syshud-settings.conf}
  '';
}
