{
  services.wbg = {
    enable = true;
    image = "/tmp/wallpaper.png";
    stretch = true;
    extraArgs = [
      "-d"
      "2"
    ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wbg.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./wbg.service}
  '';
}
