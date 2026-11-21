{ config, pkgs, ... }:
# Covers gimprc scalar and colour rendering.
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
      single-window-mode = true; # bool to yes
      show-tooltips = false;
      undo-levels = 5; # int
      tile-cache-size = {
        symbol = "4g";
      }; # memory value -- bare symbol, no quoting
      interpolation-type = {
        symbol = "cubic";
      }; # identifier -- bare symbol, no quoting
      default-brush = "2. Hardness 050"; # quoted (space + dot force quoting)
      quick-mask-color = {
        r = 1.0;
        g = 0.0;
        b = 0.0;
        a = 0.5;
      };
      default-grid = {
        xspacing = 10.0;
        fgcolor = {
          r = 0.0;
          g = 0.0;
          b = 0.0;
        };
      };
    };

    extraConfig = "(default-image (width 1920) (height 1080))\n";
  };

  nmt.script =
    let
      d =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/GIMP/3.0"
        else
          "home-files/.config/GIMP/3.0";
    in
    ''
      assertFileRegex "${d}/gimprc" "(single-window-mode yes)"
      assertFileRegex "${d}/gimprc" "(show-tooltips no)"
      assertFileRegex "${d}/gimprc" "(tile-cache-size 4g)"
      assertFileRegex "${d}/gimprc" "(interpolation-type cubic)"
      assertFileRegex "${d}/gimprc" '(default-brush "2. Hardness 050")'

      # color-rgba format
      assertFileRegex "${d}/gimprc" 'quick-mask-color .color-rgba 1.000000 0.000000 0.000000 0.500000.'
      assertFileRegex "${d}/gimprc" 'fgcolor'
      assertFileRegex "${d}/gimprc" 'default-image'

    '';
}
