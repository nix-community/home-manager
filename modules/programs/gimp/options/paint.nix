{ lib, ... }:

let
  inherit (lib)
    literalExpression
    mapAttrs
    mkOption
    types
    ;

  # Standardized type wrapper for GIMP resources that can be a file path,
  # inline raw strings, or a structured attribute set.
  resourceCollectionType =
    options:
    types.attrsOf (
      types.oneOf [
        types.path
        types.lines
        (types.submodule { inherit options; })
      ]
    );

  gimprc = import ../gimprc.nix { inherit lib; };
  inherit (gimprc) gimpValueType;

  # --- Tool Preset Helpers ---

  toolPresetLocks = {
    useFgBg = "foreground/background colours";
    useBrush = "brush selection";
    useDynamics = "paint dynamics";
    useMypaintBrush = "MyPaint brush selection";
    useGradient = "gradient selection";
    usePattern = "pattern selection";
    usePalette = "palette selection";
    useFont = "font selection";
  };
in
{
  options.programs.gimp = {
    dynamics = mkOption {
      type = resourceCollectionType {
        name = mkOption {
          type = types.str;
          description = "Dynamics preset name shown in the Dynamics dialog.";
        };
        settings = mkOption {
          type = types.attrsOf gimpValueType;
          default = { };
          description = "Freeform dynamics settings and output channels (e.g. `\"opacity-output\".\"use-pressure\" = true;`).";
        };
      };
      default = { };
      example = literalExpression ''
        {
          "pressure-opacity.gdyn" = {
            name = "Pressure Opacity";
            settings."opacity-output"."use-pressure" = true;
            settings."size-output"."use-pressure"    = true;
          };
        }
      '';
      description = ''
        Paint dynamics files (`.gdyn`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/dynamics/`.

        Values may be a path, inline text, or a structured attrset.
      '';
    };

    toolPresets = mkOption {
      type = resourceCollectionType (
        {
          name = mkOption {
            type = types.str;
            description = "Preset name shown in the Tool Presets dialog.";
          };
          iconName = mkOption {
            type = types.str;
            default = "";
            description = "GTK icon name for this preset. Leave empty to omit.";
          };
          toolOptionsClass = mkOption {
            type = types.nullOr types.nonEmptyStr;
            default = null;
            example = "GimpCropOptions";
            description = "GIMP tool-options class name. Required when `toolOptions` is non-empty.";
          };
          toolOptions = mkOption {
            type = types.attrsOf gimpValueType;
            default = { };
            description = "Tool-specific key-value pairs rendered inside the `tool-options` block.";
          };
        }
        // mapAttrs (
          _name: target:
          mkOption {
            type = types.bool;
            default = false;
            description = "Lock ${target}.";
          }
        ) toolPresetLocks
      );
      default = { };
      example = literalExpression ''
        {
          "portrait-crop.gtp" = {
            name = "Portrait Crop 3×2";
            iconName = "gimp-tool-crop";
            toolOptionsClass = "GimpCropOptions";
            toolOptions."fixed-rule-active" = true;
          };
        }
      '';
      description = ''
        Tool preset files (`.gtp`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/tool-presets/`.

        Values may be a path, inline text, or a structured attrset.
      '';
    };

    mypaintBrushes = mkOption {
      type = resourceCollectionType {
        comment = mkOption {
          type = types.str;
          default = "MyPaint brush file";
          description = "Comment string embedded in the brush file.";
        };
        group = mkOption {
          type = types.str;
          default = "";
          description = "Brush group name.";
        };
        parentBrushName = mkOption {
          type = types.str;
          default = "";
          description = "Name of the parent brush this brush is based on.";
        };
        version = mkOption {
          type = types.int;
          default = 3;
          description = "MyPaint brush file format version.";
        };
        settings = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                baseValue = mkOption {
                  type = types.float;
                  description = "Base value for this setting.";
                };
                inputs = mkOption {
                  type = types.attrsOf (types.listOf (types.listOf types.float));
                  default = { };
                  description = "Map from input-source name to [[x,y]…] control points.";
                };
              };
            }
          );
          default = { };
          description = "Brush settings map. Keys are MyPaint setting names like `radius_logarithmic`, `hardness`.";
        };
      };
      default = { };
      example = literalExpression ''
        {
          "ink-dry.myb" = {
            settings.radius_logarithmic = {
              baseValue = 2.0;
              inputs.pressure = [ [ 0.0 0.0 ] [ 1.0 1.0 ] ];
            };
            settings.hardness.baseValue = 0.9;
          };
        }
      '';
      description = ''
        MyPaint brush files (`.myb`) installed to {file}`~/.mypaint/brushes/`.

        Values may be a path, inline JSON text, or a structured attrset
        serialised to the MyPaint brush JSON format.
      '';
    };
  };
}
