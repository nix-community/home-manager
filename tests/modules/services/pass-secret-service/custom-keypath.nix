{ config, ... }:
let
  somePath = "/some/random/path/I/store/keys";
in
{
  home.stateVersion = "26.05";
  services.pass-secret-service = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    keyPath = somePath;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/pass-secret-service.service

    assertFileRegex $serviceFile '^Environment=GNUPGHOME=${somePath}$'
    assertFileRegex $serviceFile '^RequiresMountsFor=.*${somePath}.*$'
  '';
}
