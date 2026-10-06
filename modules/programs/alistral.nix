{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.alistral;
  jsonFormat = pkgs.formats.json { };
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/alistral"
    else
      ".config/alistral";
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/${configDir}/config.json"
    else
      "${config.xdg.configHome}/alistral/config.json";

in
{
  options.programs.alistral = {
    enable = mkEnableOption "alistral";
    package = mkPackageOption pkgs "alistral" { nullable = true; };
    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Merge declarative settings into a writable configuration file during
        activation, preserving settings and credentials written by the application.
        Declarative values take precedence; removing a setting from Nix does not
        remove it from the existing file. Arrays are replaced.

        Formatting is not preserved. Keep secrets out of {option}`settings`,
        since its values are still copied to the world-readable Nix store.
        New files have mode 0600; existing files retain their permissions.
      '';
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        default_user = "spanish_inquisition";
        listenbrainz_url = "https://api.listenbrainz.org/1/";
        musicbrainz_url = "http://musicbrainz.org/ws/2";
      };
      description = ''
        Configuration settings for alistral. You can see the details here:
        <https://rustynova016.github.io/Alistral/schemas/config/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      activation = {
        alistralMutableSettings = lib.mkIf (cfg.mutableSettings && cfg.settings != { }) (
          lib.hm.dag.entryAfter [ "linkGeneration" ] (
            lib.hm.generators.mkImpureConfigMerger {
              inherit pkgs;
              format = "json";
              empty = builtins.toJSON { tokens = { }; };
              jqOperation = "$dynamic * $static";
              path = settingsPath;
              staticSettings = jsonFormat.generate "alistral-mutable-settings" cfg.settings;
              mode = "600";
            }
          )
        );

        alistralImmutableSettings = lib.mkIf (!cfg.mutableSettings && cfg.settings != { }) (
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] (
            lib.hm.generators.mkImpureConfigCleanup {
              file = config.home.file."${configDir}/config.json";
            }
          )
        );
      };

      packages = mkIf (cfg.package != null) [ cfg.package ];

      file."${configDir}/config.json" = mkIf (!cfg.mutableSettings && cfg.settings != { }) {
        # Replace the name-based default while retaining ordinary user target overrides.
        target = lib.mkOverride 999 settingsPath;
        source = jsonFormat.generate "alistral-config.json" cfg.settings;
      };
    };

  };
}
