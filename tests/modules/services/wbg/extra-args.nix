_:

{
  services.wbg = {
    enable = true;
    image = "/tmp/wallpaper.png";
    extraArgs = [
      "-d"
      "2"
    ];
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wbg.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${./extra-args.service}
  '';
}
