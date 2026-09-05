_: {
  test.stubs.kanata = { };

  services.kanata = {
    enable = true;

    keyboards.remap = {
      deviceIds = [ "usb-Example_KB-event-kbd" ];
      processUnmappedKeys = true;
      defsrc = [
        "muhenkan"
        "henkan"
      ];
      layers.base = [
        "f13"
        "f14"
      ];
    };

    # `default.devices` is auto-wired to keyboards.remap.symlinkPath on Linux.
    default = {
      defsrc = [
        "caps"
        "f13"
        "f14"
      ];
      layers.base = [
        "@cap"
        "esc"
        "ret"
      ];
      extraConfig = "(defalias cap (tap-hold 200 200 caps lctl))";
    };
  };

  nmt.script = ''
    remapService=home-files/.config/systemd/user/kanata-remap.service
    defaultService=home-files/.config/systemd/user/kanata-default.service

    assertFileExists "$remapService"
    assertFileExists "$defaultService"

    assertFileRegex "$remapService"  'ExecStart=.*--symlink-path.*kanata/remap'
    assertFileRegex "$defaultService" 'ExecStart=.*--symlink-path.*kanata/default'
  '';
}
