{ config, ... }:
{
  services.awww = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@awww@"; };
    extraArgs = [
      "--no-cache"
      "--layer"
      "bottom"
    ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/awww.service
    assertFileContent $serviceFile ${./awww-graphical-session-target.service}
  '';
}
