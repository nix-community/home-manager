{ lib, ... }:
let
  inherit (lib) literalExpression mkOption types;
in
{
  options.programs.gimp = {
    brushes = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''{ "my-brush.gbr" = ./my-brush.gbr; }'';
      description = ''
        Brush files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/brushes/`.
        Supported formats: `.gbr` (raster), `.gih` (image hose), `.myb` (MyPaint).
        For parametric brushes use {option}`programs.gimp.parametricBrushes`.
      '';
    };

    parametricBrushes = mkOption {
      type = types.attrsOf (
        types.either types.path (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Brush name shown in GIMP.";
              };
              spacing = mkOption {
                type = types.float;
                default = 25.0;
                description = "Spacing between dabs as a percentage of brush diameter.";
              };
              radius = mkOption {
                type = types.float;
                description = "Brush radius in pixels.";
              };
              hardness = mkOption {
                type = types.float;
                default = 0.5;
                description = "Edge hardness from 0.0 (soft) to 1.0 (hard).";
              };
              aspectRatio = mkOption {
                type = types.float;
                default = 1.0;
                description = "Width-to-height ratio. 1.0 = circular.";
              };
              angle = mkOption {
                type = types.float;
                default = 0.0;
                description = "Rotation angle in degrees.";
              };
              shape = mkOption {
                type = types.nullOr (
                  types.enum [
                    "circle"
                    "square"
                    "diamond"
                  ]
                );
                default = null;
                description = ''
                  Brush shape for version 1.5 shaped brushes.
                  `null` produces a standard round brush (version 1.0).
                '';
              };
              spikes = mkOption {
                type = types.nullOr (types.ints.between 2 20);
                default = null;
                description = "Number of spikes for shaped brushes (2–20). Defaults to 2 when `shape` is non-null.";
              };
            };
          }
        )
      );
      default = { };
      example = literalExpression ''
        {
          "soft-round.vbr" = { name = "Soft Round 20"; radius = 20.0; hardness = 0.25; };
          "star.vbr"       = { name = "Star Brush"; radius = 15.0; shape = "circle"; spikes = 6; };
        }
      '';
      description = ''
        Parametric brush files (`.vbr`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/brushes/`.
        Values may be a path or a structured attrset rendered to VBR format.
      '';
    };

    gradients = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''{ "sunset.ggr" = ./sunset.ggr; }'';
      description = ''
        Gradient files (`.ggr`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/gradients/`.
      '';
    };

    patterns = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''{ "concrete.pat" = ./concrete.pat; }'';
      description = ''
        Pattern files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/patterns/`.
        Supported formats: `.pat` and common image formats (`.png`, `.jpg`).
      '';
    };

    palettes = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.path
          types.lines
          (types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Palette name shown in the Palettes dialog.";
              };
              columns = mkOption {
                type = types.ints.between 0 255;
                default = 0;
                description = "Number of columns in the swatch grid. 0 = flowing layout.";
              };
              colors = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      r = mkOption {
                        type = types.ints.between 0 255;
                        description = "Red (0–255).";
                      };
                      g = mkOption {
                        type = types.ints.between 0 255;
                        description = "Green (0–255).";
                      };
                      b = mkOption {
                        type = types.ints.between 0 255;
                        description = "Blue (0–255).";
                      };
                      name = mkOption {
                        type = types.str;
                        default = "";
                        description = "Optional color label.";
                      };
                    };
                  }
                );
                default = [ ];
                description = "Ordered list of palette color entries.";
              };
            };
          })
        ]
      );
      default = { };
      example = literalExpression ''
        {
          "brand.gpl" = {
            name = "Brand Colors";
            colors = [
              { r = 255; g = 0;   b = 0;   name = "Red";   }
              { r = 0;   g = 128; b = 0;   name = "Green"; }
            ];
          };
        }
      '';
      description = ''
        Palette files (`.gpl`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/palettes/`.
        Values may be a path, inline GPL text, or a structured attrset.
      '';
    };

    scripts = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "auto-save.scm" = "(define (auto-save image) (gimp-image-clean-all image))"; }
      '';
      description = ''
        Script-Fu (`.scm`) scripts installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/scripts/`.
      '';
    };

    environ = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExpression ''{ "python-path.env" = "PYTHONPATH=/my/site-packages"; }'';
      description = ''
        Environment files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/environ/`.
        Each file sets `KEY=VALUE` variables injected into plug-in processes at launch.
      '';
    };

    fonts = mkOption {
      type = types.either (types.attrsOf types.path) (types.listOf types.path);
      default = [ ];
      example = literalExpression ''[ "''${pkgs.inter}/share/fonts/truetype/inter/Inter-Regular.ttf" ]'';
      description = ''
        Font files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/fonts/`.
        May be specified as a list of font paths or as an attrset mapping destination font names to paths.
        Available inside GIMP without a system-wide font install.
      '';
    };

    plugins = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''{ "my-plugin/my-plugin" = "''${pkgs.my-gimp-plugin}/bin/my-plugin"; }'';
      description = ''
        Plug-in files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/plug-ins/`.
        Each plug-in must live in a subdirectory with the same name as the executable
        (e.g. `"my-plugin/my-plugin"`).
      '';
    };
  };
}
