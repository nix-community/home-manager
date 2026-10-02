{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Unit-tests the gimprc `{ r, g, b, a }` colour renderer directly
  sexp = import ../../../../modules/programs/gimp/gimprc.nix { inherit lib; };

  tryRenderColor = color: builtins.tryEval (sexp.renderColor color);

  validOpaqueBlack = tryRenderColor {
    r = 0.0;
    g = 0.0;
    b = 0.0;
  };
  validBoundaryInts = tryRenderColor {
    r = 0;
    g = 1;
    b = 1;
    a = 1;
  };

  invalidStringComponent = tryRenderColor {
    r = "1.0";
    g = 0.0;
    b = 0.0;
  };
  invalidBoolComponent = tryRenderColor {
    r = true;
    g = 0.0;
    b = 0.0;
  };
  invalidOutOfRangeHigh = tryRenderColor {
    # easy to reach for by analogy with 0-255 .gpl palette colours
    r = 255;
    g = 0;
    b = 0;
  };
  invalidOutOfRangeLow = tryRenderColor {
    r = -0.1;
    g = 0.0;
    b = 0.0;
  };
  invalidNullAlpha = tryRenderColor {
    r = 0.0;
    g = 0.0;
    b = 0.0;
    a = null;
  };
in
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
    };

    controllers = {
      GimpControllerMouse = {
        enabled = false;
        events = [ ];
      };
    };

    dynamics = {
      "custom.gdyn" = {
        name = "Custom Dynamics";
        settings."opacity-output"."use-pressure" = true;
        settings."force-output"."use-pressure" = true;
      };
    };

    toolPresets = {
      "crop.gtp" = {
        name = "Crop 3x2";
        toolOptionsClass = "GimpCropOptions";
        toolOptions."fixed-rule-active" = true;
      };
      "minimal.gtp" = {
        name = "Minimal Preset";
      };
    };

    parametricBrushes = {
      "star.vbr" = {
        name = "Star Brush";
        radius = 10.0;
        shape = "circle";
        spikes = 5;
      };
    };

    fonts = {
      "custom-font.ttf" = pkgs.writeText "font.ttf" "font-data";
    };
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
      assertFileRegex "${d}/gimprc" 'quick-mask-color .color-rgba 1.000000 0.000000 0.000000 0.500000.'
      assertFileRegex "${d}/controllerrc" 'mapping'
      assertFileRegex "${d}/dynamics/custom.gdyn" 'opacity-output'
      assertFileRegex "${d}/dynamics/custom.gdyn" 'use-pressure yes'
      assertFileRegex "${d}/dynamics/custom.gdyn" 'force-output'
      assertFileRegex "${d}/tool-presets/crop.gtp" 'tool-options "GimpCropOptions"'
      assertFileRegex "${d}/tool-presets/crop.gtp" 'fixed-rule-active yes'
      assertFileExists "${d}/fonts/custom-font.ttf"

      test '${builtins.toJSON validOpaqueBlack.success}' = 'true'
      test '${builtins.toJSON validOpaqueBlack.value}' = '${builtins.toJSON "(color-rgba 0.000000 0.000000 0.000000 1.000000)"}'

      test '${builtins.toJSON validBoundaryInts.success}' = 'true'
      test '${builtins.toJSON validBoundaryInts.value}' = '${builtins.toJSON "(color-rgba 0 1 1 1)"}'

      test '${builtins.toJSON invalidStringComponent.success}' = 'false'
      test '${builtins.toJSON invalidBoolComponent.success}' = 'false'
      test '${builtins.toJSON invalidOutOfRangeHigh.success}' = 'false'
      test '${builtins.toJSON invalidOutOfRangeLow.success}' = 'false'
      test '${builtins.toJSON invalidNullAlpha.success}' = 'false'
    '';
}
