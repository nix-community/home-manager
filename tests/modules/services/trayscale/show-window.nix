{ ... }: {
  services.trayscale = {
    enable = true;
    hideWindow = false;
  };

  test.stubs = { trayscale = { }; };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/trayscale.service
    assertFileExists $serviceFile
    assertFileRegex $serviceFile \
      '^ExecStart=@trayscale@/bin/trayscale$'
  '';
}
