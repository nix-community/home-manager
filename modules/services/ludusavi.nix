{ config, lib, pkgs, ... }:

let
  inherit (lib) getExe maintainers mkEnableOption mkIf mkOption;

  inherit (lib.types) bool nullOr path;

  cfg = config.services.ludusavi;
  settingsFormat = pkgs.formats.yaml { };

  configFile = if cfg.configFile == null then
    settingsFormat.generate "config.yaml" cfg.settings
  else
    cfg.configFile;
in {

  options.services.ludusavi = {
    enable = mkEnableOption "Ludusavi game backup tool";
    configFile = mkOption {
      type = nullOr path;
      default = null;
      description = ''
        Path to a Ludusavi `config.yaml`. Mutually exclusive with the `settings` option.
        See https://github.com/mtkennerly/ludusavi/blob/master/docs/help/configuration-file.md for available options.
      '';
    };
    settings = mkOption {
      type = settingsFormat.type;
      default = {
        manifest.url =
          "https://raw.githubusercontent.com/mtkennerly/ludusavi-manifest/master/data/manifest.yaml";
        roots = [ ];
        backup.path = "$XDG_STATE_HOME/backups/ludusavi";
        restore.path = "$XDG_STATE_HOME/backups/ludusavi";
      };
      example = {
        language = "en-US";
        theme = "light";
        roots = [{
          path = "~/.local/share/Steam";
          store = "steam";
        }];
        backup.path = "~/.local/state/backups/ludusavi";
        restore.path = "~/.local/state/backups/ludusavi";
      };
      description = ''
        Ludusavi configuration as an attribute set. See
        https://github.com/mtkennerly/ludusavi#configuration-file
        for available options.
      '';
    };
    backupNotification = mkOption {
      type = bool;
      default = false;
      description = ''
        Send a notification message after a successful backup.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = (cfg.settings != { }) != (cfg.configFile != null);
      message =
        "The `settings` and `configFile` options are mutually exclusive.";
    }];

    systemd.user = {
      services.ludusavi = {
        Unit.Description = "Run a game save backup with Ludusavi";
        Service = {
          Type = "oneshot";
          ExecStart = "${getExe pkgs.ludusavi} backup --force";
        } // lib.optionalAttrs cfg.backupNotification {
          ExecStartPost = "${
              getExe pkgs.libnotify
            } 'Ludusavi' 'Backup completed' -i ludusavi -a 'Ludusavi'";
        };
      };
      timers.ludusavi = {
        Unit.Description = "Run a game save backup with Ludusavi, daily";
        Timer.OnCalendar = "daily";
        Install.WantedBy = [ "timers.target" ];
      };
    };

    xdg.configFile."ludusavi/config.yaml".source = configFile;

    home.packages = [ pkgs.ludusavi ];
  };

  meta.maintainers = [ maintainers.PopeRigby ];
}
