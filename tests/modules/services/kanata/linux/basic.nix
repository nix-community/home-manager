_: {
  test.stubs.kanata = { };

  services.kanata = {
    enable = true;
    keyboards.main = {
      deviceIds = [ "usb-Example_KB-event-kbd" ];
      defsrc = [
        "caps"
        "a"
        "s"
        "d"
        "f"
      ];
      layers.base = [
        "@cap"
        "a"
        "s"
        "d"
        "f"
      ];
      extraConfig = "(defalias cap (tap-hold 200 200 caps lctl))";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/kanata-main.service
    assertFileExists "$serviceFile"

    serviceFile=$(normalizeStorePaths "$serviceFile")
    assertFileContent "$serviceFile" ${./basic-expected.service}

    assertFileContent \
      home-files/.config/kanata/main.kbd \
      ${./basic-expected.kbd}
  '';
}
