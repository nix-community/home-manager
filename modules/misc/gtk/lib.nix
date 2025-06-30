{ lib }:

let
  inherit (lib)
    literalExpression
    mkOption
    optionalAttrs
    optionalString
    types
    ;
in

{
  # Generic theme type factory function
  mkThemeType =
    {
      typeName,
      hasSize ? false,
      packageExample,
      nameExample ? "Adwaita",
    }:
    types.submodule {
      options =
        {
          package = mkOption {
            type = types.nullOr types.package;
            default = null;
            example = literalExpression packageExample;
            description =
              ''
                Package providing the ${typeName}. This package will be installed
                to your profile. If `null` then the ${typeName}
                is assumed to already be available in your profile.
              ''
              + optionalString (typeName == "theme") ''

                For the theme to apply to GTK 4, this option is mandatory.
              '';
          };

          name = mkOption {
            type = types.str;
            example = nameExample;
            description = "The name of the ${typeName} within the package.";
          };
        }
        // optionalAttrs hasSize {
          size = mkOption {
            type = types.nullOr types.int;
            default = null;
            example = 16;
            description = "The size of the cursor.";
          };
        };
    };

  # Helper function to generate the settings attribute set for a given version
  mkGtkSettings =
    {
      font,
      theme,
      iconTheme,
      cursorTheme,
    }:
    optionalAttrs (font != null) {
      gtk-font-name =
        let
          fontSize = if font.size != null then font.size else 11;
        in
        "${font.name} ${toString fontSize}";
    }
    // optionalAttrs (theme != null) { "gtk-theme-name" = theme.name; }
    // optionalAttrs (iconTheme != null) { "gtk-icon-theme-name" = iconTheme.name; }
    // optionalAttrs (cursorTheme != null) { "gtk-cursor-theme-name" = cursorTheme.name; }
    // optionalAttrs (cursorTheme != null && cursorTheme.size != null) {
      "gtk-cursor-theme-size" = cursorTheme.size;
    };

  # Package collection helper for all GTK versions
  collectGtkPackages =
    versionConfigs:
    let
      collectPackages =
        cfgVersion:
        lib.filter (pkg: pkg != null) (
          lib.optionals cfgVersion.enable (
            lib.optionals (cfgVersion.theme != null) [ cfgVersion.theme.package ]
            ++ lib.optionals (cfgVersion.iconTheme != null) [ cfgVersion.iconTheme.package ]
            ++ lib.optionals (cfgVersion.cursorTheme != null) [ cfgVersion.cursorTheme.package ]
            ++ lib.optionals (cfgVersion.font != null) [ cfgVersion.font.package ]
          )
        );
      allPackages = lib.concatMap collectPackages versionConfigs;
    in
    lib.unique allPackages;
}
