{
  services.protonmail-bridge.enable = true;

  nmt.script = ''
    local service="home-files/.config/systemd/user/protonmail-bridge.service"

    assertFileExists $service
    assertFileNotRegex $service 'Environment=PATH=.*'
    assertFileRegex $service 'ExecStart=.*/protonmail-bridge --noninteractive'
  '';
}
