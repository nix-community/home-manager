{
  config = {
    programs.eww = {
      enable = true;
    };

    nmt.script = ''
      yuckDir=home-files/.config/eww
      serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/eww.service)
      assertPathNotExists $yuckDir/eww.yuck
      assertPathNotExists $yuckDir/eww.scss
      assertPathNotExists $serviceFile
    '';
  };
}
