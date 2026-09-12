_:

{
  services.wbg = {
    enable = true;
    image = "/tmp/wallpaper.png";
    stretch = true;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wbg.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./stretch.service}
  '';
}
