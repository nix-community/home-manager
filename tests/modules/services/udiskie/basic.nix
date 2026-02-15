{
  services.udiskie.enable = true;

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/udiskie.service"
    assertFileRegex "$serviceFile" 'After=tray-xembed\.target'
    assertFileRegex "$serviceFile" 'Requires=tray-xembed\.target'
    assertFileContent "home-files/.config/udiskie/config.yml" \
        ${./basic.yml}
  '';
}
