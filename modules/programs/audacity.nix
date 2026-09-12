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

  boolToInt =
    v:
    if builtins.isBool v then (if v then "1" else "0") else lib.generators.mkValueStringDefault { } v;

  audacityKeyValue = lib.generators.mkKeyValueDefault { mkValueString = boolToInt; } "=";

  iniWithGlobalSectionFormat = pkgs.formats.iniWithGlobalSection {
    mkKeyValue = audacityKeyValue;
  };

  iniFormat = pkgs.formats.ini {
    mkKeyValue = audacityKeyValue;
  };

  xmlFormat = pkgs.formats.xml { };

  configDirAbs =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/audacity"
    else
      "${config.xdg.configHome}/audacity";

  configDirRel =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/audacity"
    else
      lib.removePrefix "${config.home.homeDirectory}/" "${config.xdg.configHome}/audacity";

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
      inherit (iniWithGlobalSectionFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          globalSection = {
            PrefsVersion = "1.1.0.0";
          };
          sections = {
            GUI = {
              ShowSplashScreen = false;
              Theme = "classic";
            };
            AudioIO = {
              DefaultSampleRate = "44100";
              SWPlaythrough = false;
            };
          };
        }
      '';
      description = ''
        Audacity preferences written to {file}`audacity.cfg`. The
        {var}`globalSection` attrset holds top-level (un-sectioned) keys, and
        {var}`sections` is a set of INI section names to key-value maps.

        Boolean values are automatically converted to `1`/`0`, as Audacity expects
        [Audacity preferences documentation](https://manual.audacityteam.org/man/audio_settings_preferences.html)
        for available options.

        Because Audacity rewrites this file at runtime the generated file is
        installed via {var}`home.activation` rather than {var}`home.file`, so
        that the file remains writable.
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

    home.activation.audacitySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.optionalString (cfg.settings != { }) ''
        install -Dm644 \
          ${iniWithGlobalSectionFormat.generate "audacity.cfg" cfg.settings} \
          "${configDirAbs}/audacity.cfg"
      ''
    );

    home.file =
      lib.optionalAttrs (cfg.pluginRegistry != { }) {
        "${configDirRel}/pluginregistry.cfg".source =
          iniFormat.generate "pluginregistry.cfg" cfg.pluginRegistry;
      }
      // lib.optionalAttrs (cfg.pluginSettings != { }) {
        "${configDirRel}/pluginsettings.cfg".source =
          iniFormat.generate "pluginsettings.cfg" cfg.pluginSettings;
      }
      // lib.optionalAttrs (cfg.eqCurves != { }) {
        "${configDirRel}/EQCurves.xml".source = xmlFormat.generate "EQCurves.xml" cfg.eqCurves;
      }
      // lib.mapAttrs' (
        name: steps: lib.nameValuePair "${configDirRel}/macros/${name}.txt" { text = renderMacro steps; }
      ) cfg.macros;
  };
}
