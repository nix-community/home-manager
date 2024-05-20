{ config, ... }: {
  xdg.mimeApps.enable = true;

  services.remmina = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    serviceFile='./home-files/.config/systemd/user/remmina.service'

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*--icon'

    mimetypeFile='./home-files/.local/share/mime/packages/application-x-rdp.xml'

    assertFileExists $mimetypeFile
    assertFileRegex $mimetypeFile '<mime-type type="application/x-rdp">'
  '';
}
