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

  cfg = config.programs.andcli;
  yamlFormat = pkgs.formats.yaml { };
  configPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/andcli"
    else
      "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/andcli";
  settingsPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/andcli/config.yaml"
    else
      "${config.xdg.configHome}/andcli/config.yaml";
  settingsFile = yamlFormat.generate "andcli-config.yaml" cfg.settings;
in
{
  options.programs.andcli = {
    enable = mkEnableOption "andcli";
    package = mkPackageOption pkgs "andcli" { nullable = true; };
    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to merge settings into a writable configuration file during
        activation. Settings declared here take precedence; other settings are
        preserved. Removing a setting here does not remove it from the file.
        Comments and formatting are not preserved.

        When switching back to immutable settings, the writable file uses
        Home Manager's normal collision and backup handling.
      '';
    };

    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        options = {
          show_usernames = false;
          show_tokens = true;
        };
      };
      description = ''
        Configuration settings for andcli. All the details can be found here:
        <https://github.com/tjblackheart/andcli/blob/7de13cc933eeb23d53558f76fefef226bd531c2c/internal/config/config.go#L16>
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = mkIf (cfg.package != null) [ cfg.package ];

      file."${configPath}/config.yaml" = mkIf (!cfg.mutableSettings && cfg.settings != { }) {
        source = settingsFile;
      };

      activation.andcliMutableSettings = lib.mkIf (cfg.mutableSettings && cfg.settings != { }) (
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "yaml";
            empty = "{}";
            jqOperation = "$dynamic * $static";
            path = settingsPath;
            staticSettings = settingsFile;
            mode = "600";
          }
        )
      );
    };

  };
}
