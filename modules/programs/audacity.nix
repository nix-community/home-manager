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

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "4.0.0";

  # Audacity 4 moved its preferences from wxWidgets to Qt settings. Qt keeps
  # top-level keys under [General] and only reads booleans spelled true/false,
  # while Audacity 3 only reads 1/0.
  isAudacity4 = lib.versionAtLeast packageVersion "4";

  hasSettings = cfg.settings.globalSection != { } || cfg.settings.sections != { };

  # Audacity 4 on macOS stores its preferences in the native defaults system
  # rather than an INI file.
  supportsSettingsFile = !(isAudacity4 && isDarwin);

  boolToInt =
    v:
    if builtins.isBool v then (if v then "1" else "0") else lib.generators.mkValueStringDefault { } v;

  iniWithGlobalSectionFormat = pkgs.formats.iniWithGlobalSection {
    mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = boolToInt; } "=";
  };

  qtIniFormat = pkgs.formats.ini { };

  settingsPath =
    if isAudacity4 then
      "${config.xdg.configHome}/Audacity/Audacity4.ini"
    else if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/audacity/audacity.cfg"
    else
      "${config.xdg.configHome}/audacity/audacity.cfg";

  settingsFile =
    if isAudacity4 then
      qtIniFormat.generate "Audacity4.ini" (
        cfg.settings.sections
        // lib.optionalAttrs (cfg.settings.globalSection != { }) {
          General = cfg.settings.sections.General or { } // cfg.settings.globalSection;
        }
      )
    else
      iniWithGlobalSectionFormat.generate "audacity.cfg" cfg.settings;

  macroDir =
    if isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/audacity/Macros"
    else
      "${config.xdg.dataHome}/audacity/Macros";

  # Audacity skips macro lines without the colon that ends the command name.
  renderMacro = lib.concatMapStrings (
    { command, params }:
    "${command}:${
      lib.concatStringsSep " " (lib.mapAttrsToList (key: value: ''${key}="${value}"'') params)
    }\n"
  );
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
          sections = {
            application.checkForUpdate = false;
            "ui/application".currentThemeCode = "dark";
          };
        }
      '';
      description = ''
        Audacity preferences. Audacity 4 reads them from
        {file}`$XDG_CONFIG_HOME/Audacity/Audacity4.ini` and Audacity 3 from
        {file}`audacity.cfg` in its configuration directory. The
        {var}`globalSection` attrset holds top-level keys, which Audacity 4
        keeps in the `General` section, and {var}`sections` maps section
        names to key-value pairs. Boolean values are written in the form the
        configured Audacity version reads. Write other values the way Audacity
        saves them; for example, Audacity 4 reads an unquoted value containing
        commas as a list.

        Audacity 3 does not start when this file is read-only, and both
        versions save their own preferences and session state to it. The
        declared keys are therefore merged into the existing file during
        activation. Other saved preferences are kept, and removing a key from
        this option does not remove it from the file.

        Audacity 4 on macOS stores its preferences outside an INI file, so this
        option has no effect there. When {option}`programs.audacity.package`
        is `null`, Audacity 4 is assumed.
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
        Audacity 3 macros written to {file}`Macros/<name>.txt` in the Audacity
        data directory. Each attribute name becomes the macro filename
        (without extension), and each list entry is one command step.
        Audacity 4 does not support macros.
      '';
    };

  };

  config = mkIf cfg.enable {
    warnings =
      lib.optional (
        hasSettings && !supportsSettingsFile
      ) "programs.audacity.settings has no effect for Audacity 4 on macOS."
      ++ lib.optional (
        isAudacity4 && cfg.macros != { }
      ) "programs.audacity.macros has no effect because Audacity 4 does not support macros.";

    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      activation.audacitySettings = mkIf (hasSettings && supportsSettingsFile) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          let
            settingsArg = lib.escapeShellArg settingsPath;
          in
          ''
            run mkdir -p ${lib.escapeShellArg (dirOf settingsPath)}
            if [[ ! -e ${settingsArg} ]]; then
              run install -m644 ${settingsFile} ${settingsArg}
            else
              run ${lib.getExe pkgs.crudini} --merge --ini-options=nospace ${settingsArg} < ${settingsFile}
            fi
          ''
        )
      );

      file = mkIf (!isAudacity4) (
        lib.mapAttrs' (
          name: steps: lib.nameValuePair "${macroDir}/${name}.txt" { text = renderMacro steps; }
        ) cfg.macros
      );
    };
  };
}
