{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.herdr.desktop;

  jsonFormat = pkgs.formats.json { };
  generatedSettings = jsonFormat.generate "herdr-app-settings.json" cfg.settings;
  # Match the merger's JSON serialization so unchanged mutable files can be
  # replaced by a store link when mutableSettings is disabled.
  settingsSource = pkgs.runCommand "herdr-app-settings.json" { } ''
    ${lib.getExe pkgs.jaq} -c '.' ${generatedSettings} > "$out"
  '';
  settingsPath = "${config.xdg.configHome}/herdr-app/settings.json";

  mutableSettingsActivation = lib.hm.generators.mkImpureConfigMerger {
    inherit pkgs;
    format = "json";
    empty = "{}";
    jqOperation = "$dynamic * $static";
    path = settingsPath;
    staticSettings = settingsSource;
    mode = "600";
  };
in
{
  meta.maintainers = [ lib.maintainers.davsanchez ];

  options.programs.herdr.desktop = {
    enable = lib.mkEnableOption "the Herdr desktop app";

    package = lib.mkPackageOption pkgs "herdr-desktop" { nullable = true; };

    mutableSettings = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to merge declared settings into a writable
        {file}`$XDG_CONFIG_HOME/herdr-app/settings.json` during activation,
        preserving settings added by Herdr or the user. Declared values take
        precedence. Removing a declaration does not remove it from the file.
        The default keeps the configuration file immutable. Switching back to
        immutable settings automatically replaces the writable file only when
        it is byte-identical to the declared settings. Changed files use Home
        Manager's normal collision and backup handling. Empty settings leave
        the file unmanaged.
      '';
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        telemetry = false;
        sounds.enabled = true;
        font = "Iosevka Term Slab";
        font_size = 14;
      };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/herdr-app/settings.json`.

        This is the desktop app's own settings file. It is separate from
        {option}`programs.herdr.settings`, which configures the Herdr TUI at
        {file}`$XDG_CONFIG_HOME/herdr/config.toml`. See the app's built-in
        guide (`herdr-app --skill`) for the available keys.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.activation.herdrDesktopMutableSettings = lib.mkIf (
      cfg.mutableSettings && cfg.settings != { }
    ) (lib.hm.dag.entryAfter [ "linkGeneration" ] mutableSettingsActivation);

    home.activation.herdrDesktopImmutableSettings =
      lib.mkIf (!cfg.mutableSettings && cfg.settings != { })
        (
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] (
            lib.hm.generators.mkImpureConfigCleanup {
              file = config.xdg.configFile."herdr-app/settings.json";
            }
          )
        );

    xdg.configFile."herdr-app/settings.json" = mkIf (!cfg.mutableSettings && cfg.settings != { }) {
      source = settingsSource;
    };
  };
}
