{
  programs.eww = {
    enable = true;
  };

  nmt.script = ''
    yuckDir=home-files/.config/eww
    serviceFile=home-files/.config/systemd/user/eww.service
    assertPathNotExists $yuckDir/eww.yuck
    assertPathNotExists $yuckDir/eww.scss
    assertPathNotExists $serviceFile
  '';
}
