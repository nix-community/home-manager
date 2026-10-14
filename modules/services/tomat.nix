{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.tomat;
  tomlFormat = pkgs.formats.toml { };
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
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
        Tomat configuration written to
        {file}`$XDG_CONFIG_HOME/tomat/config.toml` on Linux, or
        {file}`~/Library/Application Support/tomat/config.toml` on Darwin.
        See <https://jolars.github.io/tomat/configuration/> for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configDir}/tomat/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "tomat-config.toml" cfg.settings;
    };

    launchd.agents.tomat = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe cfg.package)
          "daemon"
          "run"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 5;
        EnvironmentVariables.PATH = "${config.home.profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/tomat.log";
      };
    };

    systemd.user.services.tomat = {
      Unit = {
        Description = "Tomat Pomodoro server";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} daemon run";
        Restart = "always";
        RestartSec = 5;
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
