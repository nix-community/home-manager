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

  cfg = config.programs.amber;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.amber = {
    enable = mkEnableOption "amber";
    package = mkPackageOption pkgs "amber" { nullable = true; };
    ambsSettings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        column = true;
        binary = true;
        skipped = true;
        recursive = false;
      };
      description = ''
        Configuration settings for amber's ambs tool. All the available options can be found here:
        <https://github.com/dalance/amber?tab=readme-ov-file#configurable-value>.
      '';
    };
    ambrSettings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        regex = true;
        row = true;
        statistics = true;
        interactive = false;
      };
      description = ''
        Configuration settings for amber's ambr tool. All the available options can be found here:
        <https://github.com/dalance/amber?tab=readme-ov-file#configurable-value>.
      '';
    };
  };

  config =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Preferences/com.github.dalance.amber"
        else
          ".config/amber";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configDir}/ambs.toml" = mkIf (cfg.ambsSettings != { }) {
        source = tomlFormat.generate "ambs.toml" cfg.ambsSettings;
      };
      home.file."${configDir}/ambr.toml" = mkIf (cfg.ambrSettings != { }) {
        source = tomlFormat.generate "ambr.toml" cfg.ambrSettings;
      };
    };
}
