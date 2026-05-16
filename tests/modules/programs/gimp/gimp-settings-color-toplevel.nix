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
      quick-mask-color = {
        r = 1.0;
        g = 0.0;
        b = 0.0;
        a = 0.5;
      };
    };
  };

  nmt.script = ''
    configFile="home-files/.config/GIMP/3.0/gimprc"
    assertFileExists "$configFile"
    assertFileRegex "$configFile" "quick-mask-color"
    assertFileRegex "$configFile" "R.G.B.A float"
    assertFileRegex "$configFile" "65535"
  '';
}
