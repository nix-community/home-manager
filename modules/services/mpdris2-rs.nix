{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mpdris2-rs;
in
{
  meta.maintainers = [ lib.maintainers.Kladki ];

  options.services.mpdris2-rs = {
    enable = lib.mkEnableOption "mpdris2-rs, A lightweight implementation of MPD to D-Bus bridge";

    host = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "192.168.1.1";
      description = ''
        hostname + port, or UNIX socket path of MPD server, similar to what `mpc` takes

        - if not configured, `MPD_HOST` will be used
        - if `MPD_HOST` is not set either, `localhost:6600` is the default
        - UNIX socket path has to be absolute
        - Abstract sockets are supported on Linux (socket path that starts with `@`, e.g., `@mpd_socket`)
      '';
    };

    notifications = {
      enable = lib.mkEnableOption "song change notifications";

      timeout = lib.mkOption {
        type = with lib.types; nullOr float;
        default = null;
        example = 10.0;
        description = "notification timeout (default 5 secs)";
      };

      summary = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "%artist% - %album%";
        description = ''
          Templating for the notification summary.

          See <https://github.com/szclsya/mpdris2-rs?tab=readme-ov-file#configuration> for available variables.
        '';
      };

      summaryPaused = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "%artist% - %album%";
        description = ''
          Templating for the notification summary (when paused).

          See <https://github.com/szclsya/mpdris2-rs?tab=readme-ov-file#configuration> for available variables.
        '';
      };

      body = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "%title% (%elapsed%/%duration%)";
        description = ''
          Templating for the notification body.

          See <https://github.com/szclsya/mpdris2-rs?tab=readme-ov-file#configuration> for available variables.
        '';
      };

      bodyPaused = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "%title% (%elapsed%/%duration%)";
        description = ''
          Templating for the notification body (when paused).

          See <https://github.com/szclsya/mpdris2-rs?tab=readme-ov-file#configuration> for available variables.
        '';
      };
    };

    package = lib.mkPackageOption pkgs "mpdris2-rs" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpdris2-rs" pkgs lib.platforms.linux)
    ];

    systemd.user.services.mpdris2-rs = {
      Install = {
        WantedBy = [ "default.target" ];
      };

      Unit = {
        Description = "Music Player Daemon D-Bus Bridge";
        After = [ "mpd.service" ];
      };

      Service = {
        Type = "dbus";
        Restart = "on-failure";
        ExecStart =
          let
            optionFormat = optionName: {
              option = "--${optionName}";
              sep = null;
              explicitBool = false;
            };
            args = lib.cli.toCommandLineShell optionFormat {
              host = cfg.host;
              no-notification = !cfg.notifications.enable;
              notification-timeout = cfg.notifications.timeout;
              notification-summary = cfg.notifications.summary;
              notification-summary-paused = cfg.notifications.summaryPaused;
              notification-body = cfg.notifications.body;
              notification-body-paused = cfg.notifications.bodyPaused;
            };
          in
          "${lib.getExe cfg.package} ${args}";

        BusName = "org.mpris.MediaPlayer2.mpd";
      };
    };
  };
}
