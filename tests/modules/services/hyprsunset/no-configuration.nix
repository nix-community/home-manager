{
  services.hyprsunset.enable = true;

  nmt.script = ''
    config=home-files/.config/hypr/hyprsunset.conf
    clientServiceFile=home-files/.config/systemd/user/hyprsunset.service
    assertPathNotExists $config
    assertFileExists $clientServiceFile
  '';
}
