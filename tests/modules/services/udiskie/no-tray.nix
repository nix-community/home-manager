{
  services.udiskie = {
    enable = true;
    tray = "never";
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/udiskie.service"
    assertFileNotRegex "$serviceFile" 'After=tray\.target'
    assertFileNotRegex "$serviceFile" 'Requires=tray\.target'
    assertFileContent "home-files/.config/udiskie/config.yml" \
        ${./no-tray.yml}
  '';
}
