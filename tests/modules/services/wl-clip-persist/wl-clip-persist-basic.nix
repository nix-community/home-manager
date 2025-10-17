{
  services.wl-clip-persist = {
    enable = true;
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user

    assertFileExists $servicePath/wl-clip-persist.service
    assertFileRegex $servicePath/wl-clip-persist.service "Description=Wayland clipboard persistence daemon"
    assertFileRegex $servicePath/wl-clip-persist.service "ExecStart=.* --clipboard regular"
  '';
}
