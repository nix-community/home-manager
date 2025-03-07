{
  services.flameshot = {
    enable = true;

    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/flameshot/flameshot.ini \
      ${
        builtins.toFile "expected.ini" ''
          [General]
          disabledTrayIcon=true
          showStartupLaunchMessage=false
        ''
      }
  '';
}
