{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.ludusavi;
  settingsFormat = pkgs.formats.yaml { };

  configFile =
    if cfg.configFile == null then
      settingsFormat.generate "config.yaml" cfg.settings
    else
      cfg.configFile;
in
{

  options.services.ludusavi = {
    enable = lib.mkEnableOption "Ludusavi game backup tool";

    package = lib.mkPackageOption pkgs "ludusavi" { };

    configFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      description = ''
        Path to a Ludusavi `config.yaml`. Mutually exclusive with the `settings` option.
        See https://github.com/mtkennerly/ludusavi/blob/master/docs/help/configuration-file.md for available options.
      '';
    };

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      example = "*-*-* 8:00:00";
      description = ''
        How often to run ludusavi. This value is passed to the systemd
        timer configuration as the onCalendar option.  See
        {manpage}`systemd.time(7)`
        for more information about the format.
      '';
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = {
        manifest.url = "https://raw.githubusercontent.com/mtkennerly/ludusavi-manifest/master/data/manifest.yaml";
        roots = [ ];
        backup.path = "$XDG_STATE_HOME/backups/ludusavi";
        restore.path = "$XDG_STATE_HOME/backups/ludusavi";
      };
      example = {
        language = "en-US";
        theme = "light";
        roots = [
          {
            path = "~/.local/share/Steam";
            store = "steam";
          }
        ];
        backup.path = "~/.local/state/backups/ludusavi";
        restore.path = "~/.local/state/backups/ludusavi";
      };
      description = ''
        Ludusavi configuration as an attribute set. See
        https://github.com/mtkennerly/ludusavi#configuration-file
        for available options.
      '';
    };

    backupNotification = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Send a notification message after a successful backup.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.settings != { }) != (cfg.configFile != null);
        message = "The `settings` and `configFile` options are mutually exclusive.";
      }
    ];

    systemd.user = {
      services.ludusavi = {
        Unit.Description = "Run a game save backup with Ludusavi";
        Service =
          {
            Type = "oneshot";
            ExecStart = "${lib.getExe cfg.package} backup --force";
          }
          // lib.optionalAttrs cfg.backupNotification {
            ExecStartPost = "${lib.getExe pkgs.libnotify} 'Ludusavi' 'Backup completed' -i com.mtkennerly.ludusavi -a 'Ludusavi'";
          };
      };
      timers.ludusavi = {
        Unit.Description = "Run a game save backup with Ludusavi";
        Timer.OnCalendar = cfg.frequency;
        Install.WantedBy = [ "timers.target" ];
      };
    };

    xdg.configFile."ludusavi/config.yaml".source = configFile;

    home.packages = [ cfg.package ];
  };

  meta.maintainers = [ lib.maintainers.PopeRigby ];
}
