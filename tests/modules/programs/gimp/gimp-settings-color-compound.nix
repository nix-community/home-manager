{ config, ... }:
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    settings = {
      default-grid = {
        xspacing = 10.0;
        yspacing = 10.0;
        fgcolor = {
          r = 0.0;
          g = 0.0;
          b = 0.0;
          # a omitted — defaults to 1.0
        };
        bgcolor = {
          r = 1.0;
          g = 1.0;
          b = 1.0;
        };
      };
    };
  };

  nmt.script = ''
    configFile="home-files/.config/GIMP/3.0/gimprc"
    assertFileExists "$configFile"
    assertFileRegex "$configFile" "default-grid"
    assertFileRegex "$configFile" "xspacing"
    assertFileRegex "$configFile" "fgcolor"
    assertFileRegex "$configFile" "bgcolor"
    assertFileRegex "$configFile" "R.G.B.A float"
  '';
}
