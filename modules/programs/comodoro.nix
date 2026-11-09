{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.comodoro;
  tomlFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = with lib.maintainers; [ soywod ];

  options.programs.comodoro = {
    enable = lib.mkEnableOption "Comodoro, a CLI to manage timers";

    package = lib.mkPackageOption pkgs "comodoro" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      example = lib.literalExpression ''
        {
          accounts.pomodoro = {
            default = true;
            cycles = [
              {
                name = "Work";
                duration = 1500;
              }
              {
                name = "Rest";
                duration = 300;
              }
            ];
          };
        }
      '';
      description = ''
        Comodoro configuration, a table of named accounts.
        See <https://github.com/pimalaya/comodoro/blob/master/config.sample.toml>
        for the annotated field reference.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."comodoro/config.toml".source =
      tomlFormat.generate "comodoro-config.toml" cfg.settings;
  };
}
