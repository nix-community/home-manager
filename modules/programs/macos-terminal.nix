{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    maintainers
    mapAttrs
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    literalExpression
    types
    ;

  inherit (lib.hm)
    assertions
    dag
    ;

  inherit (lib.platforms) darwin;
  inherit (pkgs.formats) plist;

  cfg = config.programs.macos-terminal;

  plistFormat = plist { escape = true; };

  # Write out the config to a plist file. This will be used to set the default
  # preferences for the Terminal.app application.
  plistFile = plistFormat.generate "com.apple.Terminal.plist" {
    "Window Settings" = mapAttrs (name: profile: profile.settings // { inherit name; }) cfg.profiles;
  };
in
{
  meta.maintainers = with maintainers; [
    kayskayskays
  ];

  options.programs.macos-terminal = {
    enable = mkEnableOption "macOS Terminal";

    profiles = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            # These settings will be passed directly to the plist generator.
            settings = mkOption {
              type = types.attrsOf plistFormat.type;

              default = { };

              example = literalExpression ''
                {
                  FontAntialias = true;
                  ShowActiveProcessInTitle = true;
                  ShowCommandKeyInTitle = true;
                };
              '';

              description = ''
                Raw plist-compatible settings for profiles within the Terminal.app
                application.

                This attribute set is intended for simple settings that have a
                well defined mapping to plist properties.

                Properties that are more obscure and require serialization as
                archived Cocoa objects, for example, are unsupported here - they
                may require dedicated module options in future.

                Attribute names should reflect the name of plist properties
                understood by the Terminal.app application. Unknown attributes
                will still be serialized, but may remain unrecognised - and thus
                unhonored - by the Terminal.app application.
              '';
            };
          };

          config.settings = {
            # For profiles, the "type" plist property should always be "Window
            # Settings".
            type = mkDefault "Window Settings";

            # Other common profile defaults.
            rowCount = mkDefault 24;
            columnCount = mkDefault 80;
            ProfileCurrentVersion = mkDefault 2.07;
          };
        }
      );

      default = { };

      example = literalExpression ''
        {
          Basic.settings = {
            FontAntialias = true;
            ShowActiveProcessInTitle = true;
          };

          "Red Sands".settings = {
            BackgroundAlphaInactive = 0.5;
            CommandString = "ssh compute";
          };
        }
      '';

      description = ''
        Configuration settings for profiles within the Terminal.app application.

        Each attribute name is used as the name of the profile, and the value
        defines the plist-compatible settings for that profile.
      '';
    };

    preferences = mkOption {
      type = types.submodule {
        options = {
          importSettings = mkOption {
            type = types.bool;

            default = true;

            description = ''
              Whether to import the generated plist into the
              `com.apple.Terminal` preferences domain during activation.
            '';
          };

          writeFile = mkOption {
            type = types.bool;

            default = false;

            description = ''
              Whether to write the generated plist into the
              `~/Library/Preferences/com.apple.Terminal.plist` file during
               activation.

               This is primarily useful for inspection and testing purposes.
            '';
          };
        };
      };

      default = { };

      example = literalExpression ''
        {
          importSettings = true;
          writeFile = false;
        }
      '';

      description = ''
        Options controlling how Terminal.app preferences are applied and
        managed.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (assertions.assertPlatform "programs.macos-terminal" pkgs darwin)
    ];

    home.file."Library/Preferences/com.apple.Terminal.plist" = mkIf cfg.preferences.writeFile {
      source = plistFile;
    };

    home.activation.appleTerminal = mkIf cfg.preferences.importSettings (
      dag.entryAfter [ "writeBoundary" ] ''
        run /usr/bin/defaults import com.apple.Terminal "${plistFile}"
      ''
    );
  };
}
