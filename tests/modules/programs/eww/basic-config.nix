{ ... }: {
  config = {
    programs.eww = {
      enable = true;
      configDir = ./config-dir;
    };

    nmt.script = ''
      yuckDir=home-files/.config/eww

      assertFileExists $yuckDir/eww.yuck
      assertFileExists $yuckDir/eww.scss
    '';
  };
}
