{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.ripasso;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.ripasso = {
    enable = lib.mkEnableOption "ripasso, a TUI for pass, built on Rust";

    package = lib.mkPackageOption pkgs "ripasso-cursive" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        stores.default = {
          path = "/home/user/.password";
          pgp_implementation = "gpg";
        };
      };
      description = ''
        Settings to write to {file}`XDG_CONFIG_HOME/ripasso/settings.toml`.

        See <https://github.com/cortex/ripasso> for more details.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ripasso/settings.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "hm_ripasso.toml" cfg.settings;
    };
  };
}
