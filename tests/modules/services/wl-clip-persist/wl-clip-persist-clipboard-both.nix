{
  services.wl-clip-persist = {
    enable = true;
    clipboardType = "both";
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user

    assertFileExists $servicePath/wl-clip-persist.service
    assertFileRegex $servicePath/wl-clip-persist.service " --clipboard both "
  '';
}
