{ config, pkgs, ... }:
# content subdirectory options testing
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
    scripts."hello.scm" = "(define (hello) (gimp-message \"Hello World\"))";
    environ."python.env" = "PYTHONPATH=/my/site-packages";

    palettes = {
      "brand.gpl" = {
        name = "Brand";
        columns = 5;
        colors = [
          {
            r = 255;
            g = 0;
            b = 0;
            name = "Red";
          }
        ];
      };
      # columns = 0 (default) must NOT emit a Columns: line
      "simple.gpl" = {
        name = "Simple";
        colors = [
          {
            r = 10;
            g = 20;
            b = 30;
          }
        ];
      };
    };

    dynamics."velocity.gdyn" = {
      name = "Velocity";
      settings."opacity-output" = {
        use-velocity = true;
        use-pressure = false;
      };
    };

    toolPresets."portrait-crop.gtp" = {
      name = "Portrait Crop";
      iconName = "gimp-tool-crop";
      toolOptionsClass = "GimpCropOptions";
      toolOptions."fixed-rule-active" = true;
    };

    mypaintBrushes."ink.myb" = {
      parentBrushName = "classic/ink";
      settings.radius_logarithmic = {
        baseValue = 2.0;
        inputs.pressure = [
          [
            0.0
            0.0
          ]
          [
            1.0
            1.0
          ]
        ];
      };
    };

    parametricBrushes = {
      "round.vbr" = {
        name = "Round 20";
        radius = 20.0;
      };
      # shape set → version 1.5
      "star.vbr" = {
        name = "Star";
        radius = 15.0;
        shape = "circle";
        spikes = 6;
      };
    };

    fonts =
      let
        fakeFont = pkgs.runCommand "fake-inter" { } ''
          mkdir -p "$out"
          printf 'fake ttf' > "$out/Inter-Regular.ttf"
        '';
      in
      [ "${fakeFont}/Inter-Regular.ttf" ];

    plugins."my-plugin/my-plugin" = builtins.toFile "my-plugin" "#!/bin/sh\necho hello";

    themes."MyDark" = pkgs.runCommand "fake-theme" { } ''
      mkdir -p "$out/gtk-3.0"
      echo '* { color: black; }' > "$out/gtk-3.0/gtk.css"
    '';

    icons."Papirus" = pkgs.runCommand "fake-icons" { } ''
      mkdir -p "$out"
      printf '[Icon Theme]\nName=Papirus\n' > "$out/index.theme"
    '';
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
      assertFileRegex    "${d}/palettes/brand.gpl"          "Columns: 5"
      assertFileNotRegex "${d}/palettes/simple.gpl"         "Columns:"
      assertFileRegex    "${d}/dynamics/velocity.gdyn"      "use-velocity yes"
      assertFileRegex    "${d}/dynamics/velocity.gdyn"      "use-pressure no"
      assertFileRegex    "${d}/tool-presets/portrait-crop.gtp" "gimp-tool-crop"
      assertFileRegex    "${d}/tool-presets/portrait-crop.gtp" "fixed-rule-active yes"
      assertFileRegex    "${d}/tool-presets/portrait-crop.gtp" "use-font no"
      # MyPaint brushes bypass the GIMP config directory and XDG prefs entirely;
      # they always land at ~/.mypaint/brushes/ (see programs.gimp.mypaintBrushes).
      assertFileRegex    "home-files/.mypaint/brushes/ink.myb" "base_value"
      assertFileRegex    "${d}/brushes/round.vbr"           "^1\.0$"
      assertFileRegex    "${d}/brushes/star.vbr"            "^1\.5$"

      assertFileExists "${d}/fonts/Inter-Regular.ttf"
      assertFileExists "${d}/plug-ins/my-plugin/my-plugin"
      assertFileExists "${d}/themes/MyDark/gtk-3.0/gtk.css"
      assertFileExists "${d}/icons/Papirus/index.theme"
    '';
}
