{
  config = {
    programs.eww = {
      enable = true;
    };

    nmt.script = ''
      yuckDir=home-files/.config/eww

      assertPathNotExists  $yuckDir/eww.yuck
    '';
  };
}
