{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bottom;

  tomlFormat = pkgs.formats.toml { };

in {
  options = {
    programs.bottom = {
      enable = mkEnableOption ''
        bottom, a cross-platform graphical process/system monitor with a
        customizable interface'';

      package = mkOption {
        type = types.package;
        default = pkgs.bottom;
        defaultText = literalExpression "pkgs.bottom";
        description = "Package providing {command}`bottom`.";
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/bottom/bottom.toml`.

          See <https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml>
          for the default configuration.
        '';
        example = literalExpression ''
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."bottom/bottom.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "bottom.toml" cfg.settings;
    };
  };

  meta.maintainers = [ ];
}
