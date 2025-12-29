{ config, ... }:
{
  programs.sunpaper = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = null; };
    settings = {
      latitude = "38.9072N";
      longitude = "77.0369W";
      wallpaperPath = "${./wallpapers}";
      wallpaperMode = "scale";
    };
  };

  nmt.script = ''
    configFile=home-files/.config/sunpaper/config
    assertFileExists $configFile
    assertFileContains $configFile "latitude=38.9072N"
  '';
}
