{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.programs.secretspec;
  tomlFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = [ lib.maintainers.yethal ];

  options.programs.secretspec = {
    enable = lib.mkEnableOption "secretspec";

    package = lib.mkPackageOption pkgs "secretspec" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        defaults = {
          provider = "keyring";
          profile = "default";
          providers = {
            dotenv = "dotenv://";
          };
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/secretspec/config.toml`.

        See <https://secretspec.dev/reference/cli/#config-global-show> for
        available options and documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."secretspec/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
