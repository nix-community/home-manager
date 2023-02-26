{ config, pkgs, ... }:

{
  services.pass-secret-service = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    storePath = "/mnt/password-store";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/pass-secret-service.service

    assertFileExists $serviceFile
    assertFileRegex $serviceFile 'ExecStart=.*/bin/pass_secret_service'
    assertFileRegex $serviceFile '/mnt/password-store'
  '';
}
