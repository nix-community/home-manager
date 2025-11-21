{
  services.udiskie.enable = true;

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/udiskie.service"
    assertFileRegex "$serviceFile" 'After=tray\.target'
    assertFileRegex "$serviceFile" 'Requires=tray\.target'
    assertFileContent "home-files/.config/udiskie/config.yml" \
        ${./basic.yml}
  '';
}
