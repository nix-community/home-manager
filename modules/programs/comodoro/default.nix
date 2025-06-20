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
  meta.maintainers = with lib.hm.maintainers; [ soywod ];

  options.programs.comodoro = {
    enable = lib.mkEnableOption "Comodoro, a CLI to manage your time";

    package = lib.mkPackageOption pkgs "comodoro" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Comodoro configuration.
        See <https://pimalaya.org/comodoro/cli/configuration/> for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."comodoro/config.toml".source =
      tomlFormat.generate "comodoro-config.toml" cfg.settings;
  };
}
