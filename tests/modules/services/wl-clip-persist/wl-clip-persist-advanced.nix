{
  services.wl-clip-persist = {
    enable = true;
    clipboardType = "regular";
    extraOptions = [
      "--write-timeout"
      "1000"
      "--ignore-event-on-error"
      "--selection-size-limit"
      "1048576"
    ];
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user

    assertFileExists $servicePath/wl-clip-persist.service
    assertFileRegex $servicePath/wl-clip-persist.service "Description=Wayland clipboard persistence daemon"
    assertFileRegex $servicePath/wl-clip-persist.service " --clipboard regular "
    assertFileRegex $servicePath/wl-clip-persist.service " --write-timeout 1000"
    assertFileRegex $servicePath/wl-clip-persist.service " --ignore-event-on-error"
    assertFileRegex $servicePath/wl-clip-persist.service " --selection-size-limit 1048576"
  '';
}
