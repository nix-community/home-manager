_:

{
  services.wbg = {
    enable = true;
    image = "/tmp/wallpaper.png";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wbg.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./basic.service}
  '';
}
