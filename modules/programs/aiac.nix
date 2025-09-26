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

  cfg = config.programs.aiac;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.aiac = {
    enable = mkEnableOption "aiac";
    package = mkPackageOption pkgs "aiac" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        default_backend = "official_openai";
        backends = {
          official_openai = {
            type = "openai";
            api_key = "API KEY";
            default_model = "gpt-4o";
          };

          localhost = {
            type = "ollama";
            url = "http://localhost:11434/api";
          };
        };
      };
      description = ''
        Configuration settings for aiac. All the available options can be found here:
        <https://github.com/gofireflyio/aiac/?tab=readme-ov-file#configuration>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."aiac/aiac.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "aiac.toml" cfg.settings;
    };
  };
}
