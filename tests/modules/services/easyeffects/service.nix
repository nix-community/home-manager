{ ... }:

{
  services.easyeffects = {
    enable = true;
  };

  test.stubs.easyeffects = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/easyeffects.service

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/easyeffects'
  '';
}
