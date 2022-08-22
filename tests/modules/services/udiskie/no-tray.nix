{
  config = {
    services.udiskie = {
      enable = true;
      tray = "never";
    };

    test.stubs.udiskie = { };

    nmt.script = ''
      serviceFile="home-files/.config/systemd/user/udiskie.service"
      assertFileNotRegex "$serviceFile" 'After=tray\.target'
      assertFileNotRegex "$serviceFile" 'Requires=tray\.target'
      assertFileContent "home-files/.config/udiskie/config.yml" \
          ${./no-tray.yml}
    '';
  };
}
