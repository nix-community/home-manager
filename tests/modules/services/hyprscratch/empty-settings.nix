{
  services.hyprscratch.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/hypr"

    serviceFile=home-files/.config/systemd/user/hyprscratch.service
    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/hyprscratch init$'
  '';
}
