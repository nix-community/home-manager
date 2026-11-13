{
  services.wbg = {
    enable = true;
    image = "/tmp/wallpaper.png";
    extraArgs = [ "-s" ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wbg.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./wbg.service}
  '';
}
