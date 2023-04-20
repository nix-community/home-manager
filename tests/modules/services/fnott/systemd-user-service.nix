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

      assertFileContent \
        home-files/.local/share/dbus-1/services/fnott.service \
        ${./systemd-user-dbus-service-expected.service}
    '';
  };
}
