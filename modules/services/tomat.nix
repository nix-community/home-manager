{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.tomat;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ jolars ];

  options.services.tomat = {
    enable = lib.mkEnableOption "Tomat Pomodoro server";

    package = lib.mkPackageOption pkgs "tomat" { };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };

      default = { };

      example = {
        timer = {
          work = 25;
          break = 5;
          auto_advance = false;
        };

        sound = {
          enabled = true;
        };

        notification = {
          enabled = true;
        };
      };

      description = ''
        Tomat configuration.
        See <https://github.com/jolars/tomat/blob/main/docs/configuration.md> for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "tomat/config.toml" = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "tomat-config.toml" cfg.settings;
      };
    };

    systemd.user.services.tomat = {
      Unit = {
        Description = "Tomat Pomodoro server";
        After = [ "graphical.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} daemon run";
        Restart = "always";
        RestartSec = 5;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
