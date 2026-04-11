{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    types
    ;

  cfg = config.programs.audacity;

  iniFormat = pkgs.formats.ini { };
  xmlFormat = pkgs.formats.xml { };

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/audacity"
    else
      ".config/audacity";

  renderMacro =
    steps:
    lib.concatMapStringsSep "\n" (
      { command, params }:
      command
      +
        lib.optionalString (params != { })
          "\t${lib.concatStringsSep " " (lib.mapAttrsToList (key: value: ''${key}="${value}"'') params)}"
    ) steps
    + "\n";
in

{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  options.programs.audacity = {
    enable = mkEnableOption "Audacity, a multi-track audio editor and recorder";

    package = mkPackageOption pkgs "audacity" {
      nullable = true;
    };

    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          GUI = {
            ShowSplashScreen = "0";
            Theme = "classic";
          };
          AudioIO = {
            DefaultSampleRate = "44100";
            SWPlaythrough = "0";
          };
        }
      '';
      description = ''
        Audacity preferences written to {file}`audacity.cfg`. Each attribute
        key corresponds to an INI section name, and its value is a set of
        key-value preference entries for that section.

        See the
        [Audacity preferences documentation](https://manual.audacityteam.org/man/audio_settings_preferences.html)
        for available options.
      '';
    };

    pluginRegistry = mkOption {
      inherit (iniFormat) type;
      default = { };
      description = ''
        Plugin registry written to {file}`pluginregistry.cfg`. Controls which
        plugins are registered and their enabled state.
      '';
    };

    pluginSettings = mkOption {
      inherit (iniFormat) type;
      default = { };
      description = ''
        Per-plugin parameter state written to {file}`pluginsettings.cfg`.
      '';
    };

    macros = mkOption {
      type = types.attrsOf (
        types.listOf (
          types.submodule {
            options = {
              command = mkOption {
                type = types.str;
                description = "Audacity command name.";
              };
              params = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Command parameters as key-value pairs.";
              };
            };
          }
        )
      );
      default = { };
      example = lib.literalExpression ''
        {
          "normalize-and-export" = [
            { command = "Normalize"; params = { ApplyGain = "0"; PeakLevel = "-1"; }; }
            { command = "Export2"; params = { Filename = "output"; Format = "FLAC"; }; }
          ];
        }
      '';
      description = ''
        Audacity macros written to {file}`macros/<name>.txt`. Each attribute
        name becomes the macro filename (without extension), and each list
        entry is one command step.
      '';
    };

    eqCurves = mkOption {
      inherit (xmlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          equalizationeffect.curve = [
            {
              "@name" = "My Curve";
              point = [
                { "@f" = "20.0"; "@d" = "0.0"; }
                { "@f" = "1000.0"; "@d" = "3.0"; }
              ];
            }
          ];
        }
      '';
      description = ''
        Named EQ presets written to {file}`EQCurves.xml` using
        {var}`pkgs.formats.xml`. See the Nixpkgs manual for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file =
      lib.optionalAttrs (cfg.settings != { }) {
        "${configDir}/audacity.cfg".source = iniFormat.generate "audacity.cfg" cfg.settings;
      }
      // lib.optionalAttrs (cfg.pluginRegistry != { }) {
        "${configDir}/pluginregistry.cfg".source =
          iniFormat.generate "pluginregistry.cfg" cfg.pluginRegistry;
      }
      // lib.optionalAttrs (cfg.pluginSettings != { }) {
        "${configDir}/pluginsettings.cfg".source =
          iniFormat.generate "pluginsettings.cfg" cfg.pluginSettings;
      }
      // lib.optionalAttrs (cfg.eqCurves != { }) {
        "${configDir}/EQCurves.xml".source = xmlFormat.generate "EQCurves.xml" cfg.eqCurves;
      }
      // lib.mapAttrs' (
        name: steps: lib.nameValuePair "${configDir}/macros/${name}.txt" { text = renderMacro steps; }
      ) cfg.macros;
  };
}
