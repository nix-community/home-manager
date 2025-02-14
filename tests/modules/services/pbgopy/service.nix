{
  services.pbgopy.enable = true;

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/pbgopy.service

    assertFileExists $serviceFile

    assertFileContains $serviceFile \
      'ExecStart=@pbgopy@/bin/pbgopy serve --port 9090 --ttl 24h'
  '';
}
