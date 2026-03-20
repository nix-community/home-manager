{ config, ... }:
let
  somePath = "/some/random/path/I/store/pwds";
in
{
  home.stateVersion = "25.11";
  programs.password-store = {
    enable = true;
    settings.PASSWORD_STORE_DIR = somePath;
  };
  services.pass-secret-service = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = ''
    assertFileContains home-files/.config/systemd/user/pass-secret-service.service \
      'ExecStart=${config.services.pass-secret-service.package}/bin/pass_secret_service --path ${somePath}'
  '';
}
