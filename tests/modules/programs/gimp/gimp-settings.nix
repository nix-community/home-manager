{ config, pkgs, ... }:
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
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

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/GIMP/3.0"
        else
          "home-files/.config/GIMP/3.0";
    in
    ''
      assertFileExists "${configDir}/gimprc"
      assertFileRegex "${configDir}/gimprc" "(single-window-mode yes)"
      assertFileRegex "${configDir}/gimprc" "(undo-levels 5)"
      assertFileRegex "${configDir}/gimprc" "(tile-cache-size 4g)"
      assertFileRegex "${configDir}/gimprc" "(interpolation-type cubic)"
      assertFileRegex "${configDir}/gimprc" '(default-brush "2. Hardness 050")'
      assertFileRegex "${configDir}/gimprc" "(show-tooltips no)"
      assertFileRegex "${configDir}/gimprc" "(default-image"
      assertFileRegex "${configDir}/gimprc" "(width 1920)"
    '';
}
