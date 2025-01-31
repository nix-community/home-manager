{
  services.hypridle.enable = true;

  nmt.script = ''
    config=home-files/.config/hypr/hypridle.conf
    clientServiceFile=home-files/.config/systemd/user/hypridle.service
    assertPathNotExists $config
    assertFileExists $clientServiceFile
  '';
}
