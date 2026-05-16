{ config, ... }:
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      # version is read to derive configVersion
      version = "3.0.8";
    };

    settings = {
      single-window-mode = true;
      undo-levels = 5;
      tile-cache-size = "4g";
      interpolation-type = "cubic";
      default-brush = "2. Hardness 050";
      show-tooltips = false;
    };

    extraConfig = ''
      (default-image
          (width 1920)
          (height 1080)
          (unit pixels)
          (xresolution 300.000000)
          (yresolution 300.000000)
          (resolution-unit inches)
          (color-mode rgb)
          (precision linear-unsigned-8)
          (fill-type background)
          (comment "Created with GIMP"))
    '';
  };

  nmt.script = ''
    configFile="home-files/.config/GIMP/3.0/gimprc"
    assertFileExists "$configFile"
    assertFileRegex "$configFile" "(single-window-mode yes)"
    assertFileRegex "$configFile" "(undo-levels 5)"
    assertFileRegex "$configFile" "(tile-cache-size 4g)"
    assertFileRegex "$configFile" "(interpolation-type cubic)"
    assertFileRegex "$configFile" "(default-brush \"2. Hardness 050\")"
    assertFileRegex "$configFile" "(show-tooltips no)"
    assertFileRegex "$configFile" "(default-image"
  '';
}
