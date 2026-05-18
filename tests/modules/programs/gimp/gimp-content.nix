{ config, ... }:
{
  programs.gimp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "gimp";
      outPath = "@gimp@";
      version = "3.0.8";
    };

    brushes."my-brush.gbr" = builtins.toFile "my-brush.gbr" "GIMP brush";
    palettes."brand.gpl" = ''
      GIMP Palette
      Name: Brand
      #
      255   0   0	Red
    '';
    scripts."hello.scm" = ''
      (define (hello) (gimp-message "Hello"))
    '';
    environ."python.env" = "PYTHONPATH=/my/site-packages";
  };

  nmt.script = ''
    assertFileExists "home-files/.config/GIMP/3.0/brushes/my-brush.gbr"
    assertFileExists "home-files/.config/GIMP/3.0/palettes/brand.gpl"
    assertFileRegex  "home-files/.config/GIMP/3.0/palettes/brand.gpl" "Brand"
    assertFileExists "home-files/.config/GIMP/3.0/scripts/hello.scm"
    assertFileRegex  "home-files/.config/GIMP/3.0/scripts/hello.scm" "hello"
    assertFileExists "home-files/.config/GIMP/3.0/environ/python.env"
    assertFileRegex  "home-files/.config/GIMP/3.0/environ/python.env" "PYTHONPATH"
  '';
}
