_: {
  test.stubs.kanata = { };

  # No `keyboards` entries — just a standalone `default` config.
  services.kanata = {
    enable = true;
    default = {
      deviceIds = [ "usb-Example_KB-event-kbd" ];
      defsrc = [
        "caps"
        "a"
      ];
      layers.base = [
        "esc"
        "a"
      ];
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/kanata-default.service
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" 'ExecStart=.*--symlink-path.*kanata/default'
  '';
}
