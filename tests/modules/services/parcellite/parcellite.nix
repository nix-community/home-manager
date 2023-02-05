{ config, pkgs, ... }:

{
  services.parcellite = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "parcellite";
      outPath = "@parcellite@";
    };
    extraOptions = [ "--no-icon" ];
  };

  nmt.script = ''
    assertFileContent \
        "home-files/.config/systemd/user/parcellite.service" \
        ${./parcellite-expected.service}
  '';
}
