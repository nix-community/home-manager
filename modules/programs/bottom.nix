{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.programs.bottom;

  tomlFormat = pkgs.formats.toml { };

in
{
  options = {
    programs.bottom = {
      enable = lib.mkEnableOption ''
        bottom, a cross-platform graphical process/system monitor with a
        customizable interface'';

      package = lib.mkPackageOption pkgs "bottom" { nullable = true; };

      settings = lib.mkOption {
        type = tomlFormat.type;
        default = { };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/bottom/bottom.toml`.

          See <https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml>
          for the default configuration.
        '';
        example = lib.literalExpression ''
          {
            flags = {
              avg_cpu = true;
              temperature_type = "c";
            };

            colors = {
              low_battery_color = "red";
            };
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."bottom/bottom.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "bottom.toml" cfg.settings;
    };
  };

  meta.maintainers = [ ];
}
