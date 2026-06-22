{ config, ... }:
{
  home.stateVersion = "25.05"; # <= 25.11
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_KEY = "12345678";
  };
  services.pass-secret-service = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/pass-secret-service.service

    assertFileExists $serviceFile
    assertFileNotRegex $serviceFile '--path '
  '';
}
