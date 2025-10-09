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
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.andcli = {
    enable = mkEnableOption "andcli";
    package = mkPackageOption pkgs "andcli" { nullable = true; };
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

  config =
    let
      configPath =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/andcli"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/andcli";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configPath}/config.yaml" = mkIf (cfg.settings != { }) {
        source = yamlFormat.generate "andcli-config.yaml" cfg.settings;
      };
    };
}
