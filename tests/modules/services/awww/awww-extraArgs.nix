{ config, ... }:
{
  services.awww = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "awww";
      outPath = "@awww@";
    };
    extraArgs = [
      "--no-cache"
      "--layer"
      "bottom"
    ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/awww.service
    assertFileExists $serviceFile
    assertFileContains $serviceFile "ExecStart=@awww@/bin/awww-daemon --no-cache --layer bottom";
  '';
}
