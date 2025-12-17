{ config, ... }:

{
  home.stateVersion = "25.05"; # <= 25.11
  programs.password-store.enable = true;
  services.pass-secret-service = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/pass-secret-service.service

    assertFileExists $serviceFile
    assertFileRegex $serviceFile '^ExecStart=.*/bin/pass_secret_service --path ${config.xdg.dataHome}/password-store$'
  '';
}
