{ config, pkgs, ... }:

{
  config = {
    services.eww = { enable = true; };

    test.stubs.eww = { name = "eww"; };

    nmt.script = ''
      serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/eww.service)
      assertFileContent "$serviceFile" ${./basic-configuration.service}
    '';
  };
}
