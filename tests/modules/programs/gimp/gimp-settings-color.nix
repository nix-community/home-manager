{ config, pkgs, ... }:
# Covers colour rendering in both positions:
#   - top-level: quick-mask-color → (color "R'G'B'A float" …) directly in gimprc
#   - inside compound: default-grid fgcolor/bgcolor → same format as children
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
      quick-mask-color = {
        r = 1.0;
        g = 0.0;
        b = 0.0;
        a = 0.5;
      };
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
      # Top-level colour: r=1.0→65535, a=0.5→32768
      assertFileRegex "${configDir}/gimprc" "quick-mask-color"
      assertFileRegex "${configDir}/gimprc" "R.G.B.A float"
      assertFileRegex "${configDir}/gimprc" "65535"
      assertFileRegex "${configDir}/gimprc" "32768"
      # Compound colour: default-grid with named fgcolor/bgcolor children
      assertFileRegex "${configDir}/gimprc" "default-grid"
      assertFileRegex "${configDir}/gimprc" "fgcolor"
      assertFileRegex "${configDir}/gimprc" "bgcolor"
      assertFileRegex "${configDir}/gimprc" "xspacing"
    '';
}
