{ config, ... }:
{
  services.tailscale-systray = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "tailscale";
      version = "1.88.1";
      outPath = "@tailscale@";
    };
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/tailscale-systray.service
    assertFileExists $serviceFile
    assertFileRegex $serviceFile \
      '^ExecStart=@tailscale@/bin/tailscale systray$'
  '';
}
