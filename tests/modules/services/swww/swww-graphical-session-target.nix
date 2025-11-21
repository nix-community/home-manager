{ config, ... }:
{
  services.swww = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@swww@"; };
    extraArgs = [
      "--no-cache"
      "--layer"
      "bottom"
    ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/swww.service
    assertFileContent $serviceFile ${./swww-graphical-session-target.service}
  '';
}
