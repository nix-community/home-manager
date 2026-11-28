{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapAttrs
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.misc.material-icons;

  normalizeIconEntry =
    value:
    if builtins.isString value then
      {
        path = value;
        color = null;
      }
    else
      {
        inherit (value) path;
        color = value.color or null;
      };

  individualIconEntrys = mapAttrs (_: normalizeIconEntry) cfg.icons;

  groupedIconEntrys = concatMapAttrs (
    _: iconGroupCfg:
    mapAttrs (_destinationPath: sourcePath: {
      path = sourcePath;
      inherit (iconGroupCfg) color;
    }) iconGroupCfg.icons
  ) cfg.groups;

  finalIconEntries = individualIconEntrys // groupedIconEntrys;
  rootIconPath = "share/icons/material";
in
{
  options.misc.material-icons = {
    enable = mkEnableOption "Material Design Icons";

    hash = mkOption {
      type = types.str;
      description = ''
        The collective hash of the icons being imported.  Will need to be
        updated as you add/remove icons from your import.
      '';
    };

    rev = mkOption {
      type = types.str;
      description = "The GitHub commit to clone.";
      default = "941fa95d7f6084a599a54ca71bc565f48e7c6d9e";
    };

    icons = mkOption {
      description = "A map of local icon paths to their paths in the git repo.";
      example = ''
        icons = {
          "scalable/launcher.svg" = "symbols/web/action_key/materialsymbolssharp/action_key_fill1_40px.svg";
          "scalable/launcher-white.svg" = {
            path = "symbols/web/action_key/materialsymbolssharp/action_key_fill1_40px.svg";
            color = "white";
          };
        };
      '';
      default = { };
      type = types.attrsOf (
        types.either types.str (
          types.submodule {
            options = {
              path = mkOption {
                type = types.str;
                description = "Path to the icon in the git repo.";
              };
              color = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Fill color to apply to the SVG icon (e.g., 'white', '#FFFFFF').
                  See <https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/fill> for details.
                '';
              };
            };
          }
        )
      );
    };

    groups = mkOption {
      description = "To apply the same color to multiple icons, you can use groups.";
      example = ''
        groups = {
          "white-icons" = {
            color = "white";
            icons = {
              "scalable/launcher.svg" = "symbols/web/action_key/materialsymbolssharp/action_key_fill1_40px.svg";
              "scalable/settings.svg" = "symbols/web/settings/materialsymbolssharp/settings_fill1_40px.svg";
            };
          };
        };
      '';
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            color = mkOption {
              type = types.str;
              description = ''
                The fill color to apply to icons in this group (e.g., 'white', '#FFFFFF').
                See <https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/fill> for details.
              '';
            };
            icons = mkOption {
              type = types.attrsOf types.str;
              description = "A map of local icon paths to their paths in the git repo.";
            };
          };
        }
      );
    };

    package = mkOption {
      type = types.package;
      readOnly = true;
      description = "The resulting derivation containing the icons.";
    };

    absolutePath = mkOption {
      type = types.functionTo types.path;
      readOnly = true;
      description = "Returns the absolute path for an icon with the given relative path.";
    };
  };

  config = mkIf cfg.enable {
    misc.material-icons.package = pkgs.callPackage ./package.nix {
      inherit (cfg) rev hash;
      inherit rootIconPath;
      iconEntries = finalIconEntries;
    };
    misc.material-icons.absolutePath = relativePath: "${cfg.package}/${rootIconPath}/${relativePath}";

    home.packages = [ cfg.package ];
  };

  meta.maintainers = [ lib.maintainers.appsforartists ];
}
