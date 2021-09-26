{ config, lib, pkgs, ... }:

{
  config = {
    services.fnott = {
      enable = true;
      package = config.lib.test.mkStubPackage { outPath = "@fnott@"; };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/systemd/user/fnott.service \
        ${./systemd-user-service-expected.service}
    '';
  };
}
