{ config, ... }: {
  xdg.mimeApps.enable = true;

  services.remmina = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    addRdpMimeTypeAssoc = false;
    systemdService = {
      enable = true;
      startupFlags = [ "--icon" "--enable-extra-hardening" ];
    };
  };

  nmt.script = ''
    serviceFile='./home-files/.config/systemd/user/remmina.service'

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/dummy'
    assertFileRegex $serviceFile "dummy --icon --enable-extra-hardening"

    mimetypeFile='./home-files/.local/share/mime/packages/application-x-rdp.xml'

    assertPathNotExists $mimetypeFile
  '';
}
