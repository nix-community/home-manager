{
  services.tailscale-systray = {
    enable = true;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/tailscale-systray.service
    assertFileExists $serviceFile
    assertFileRegex $serviceFile \
      '^ExecStart=@tailscale@/bin/tailscale systray$'
  '';
}
