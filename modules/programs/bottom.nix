{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bottom;

  tomlFormat = pkgs.formats.toml { };

  configDir = if pkgs.stdenv.isDarwin then
    "Library/Application Support"
  else
    config.xdg.configHome;

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
        description = "Package providing <command>bottom</command>.";
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/bottom/bottom.toml</filename> on Linux or
          <filename>$HOME/Library/Application Support/bottom/bottom.toml</filename> on Darwin.
          </para><para>
          See <link xlink:href="https://github.com/ClementTsang/bottom/blob/master/sample_configs/default_config.toml"/>
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

    home.file."${configDir}/bottom/bottom.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "bottom.toml" cfg.settings;
    };
  };

  meta.maintainers = [ maintainers.polykernel ];
}
