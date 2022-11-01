{
  config = {
    services.udiskie.enable = true;

    test.stubs.udiskie = { };

    nmt.script = ''
      serviceFile="home-files/.config/systemd/user/udiskie.service"
      assertFileRegex "$serviceFile" 'After=tray\.target'
      assertFileRegex "$serviceFile" 'Requires=tray\.target'
      assertFileContent "home-files/.config/udiskie/config.yml" \
          ${./basic.yml}
    '';
  };
}
