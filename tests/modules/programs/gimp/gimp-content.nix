{ config, pkgs, ... }:
# Covers all text-content subdirectory options: brushes, gradients, patterns,
# palettes, scripts, dynamics, tool-presets, mypaint-brushes, environ.
{
  home.enableNixpkgsReleaseCheck = false;

  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    brushes."my-brush.gbr" = builtins.toFile "my-brush.gbr" "GIMP brush";
    gradients."sunset.ggr" = "GIMP Gradient\nName: Sunset\n";
    patterns."concrete.pat" = builtins.toFile "concrete.pat" "GIMP pattern";
    palettes."brand.gpl" = ''
      GIMP Palette
      Name: Brand
      #
      255   0   0	Red
    '';
    scripts."hello.scm" = "(define (hello) (gimp-message \"Hello World\"))";
    dynamics."pressure.dynamics" = "<?xml version=\"1.0\"?><dynamics name=\"Pressure\">";
    toolPresets."soft-eraser.gtp" = "<?xml version=\"1.0\"?><tool-preset name=\"Soft Eraser\">";
    mypaintBrushes."ink-dry.myb" = builtins.toFile "ink-dry.myb" "{\"version\": 3}";
    environ."python.env" = "PYTHONPATH=/my/site-packages";
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
      assertFileExists "${configDir}/brushes/my-brush.gbr"
      assertFileExists "${configDir}/gradients/sunset.ggr"
      assertFileRegex  "${configDir}/gradients/sunset.ggr" "Sunset"
      assertFileExists "${configDir}/patterns/concrete.pat"
      assertFileExists "${configDir}/palettes/brand.gpl"
      assertFileRegex  "${configDir}/palettes/brand.gpl" "Brand"
      assertFileRegex  "${configDir}/palettes/brand.gpl" "255.*0.*0"
      assertFileExists "${configDir}/scripts/hello.scm"
      assertFileRegex  "${configDir}/scripts/hello.scm" "Hello World"
      assertFileExists "${configDir}/dynamics/pressure.dynamics"
      assertFileRegex  "${configDir}/dynamics/pressure.dynamics" "Pressure"
      assertFileExists "${configDir}/tool-presets/soft-eraser.gtp"
      assertFileRegex  "${configDir}/tool-presets/soft-eraser.gtp" "Soft Eraser"
      assertFileExists "${configDir}/mypaint-brushes/ink-dry.myb"
      assertFileExists "${configDir}/environ/python.env"
      assertFileRegex  "${configDir}/environ/python.env" "PYTHONPATH"
    '';
}
