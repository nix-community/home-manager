{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.worktrunk;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.eveeifyeve ];

  options.programs.worktrunk = {
    enable = lib.mkEnableOption "worktrunk";

    package = lib.mkPackageOption pkgs "worktrunk" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        skip-shell-integration-prompt = true;
        post-start = {
          copy = "wt step copy-ignored";
        };
      };
      description = ''
        Configuration written to `$XDG_CONFIG_HOME/worktrunk/config.toml`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile."worktrunk/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };
  };
}
