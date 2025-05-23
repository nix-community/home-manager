{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;

  cfg = config.services.mpdris2;

  toIni = lib.generators.toINI {
    mkKeyValue =
      key: value:
      let
        value' = if lib.isBool value then (if value then "True" else "False") else toString value;
      in
      "${key} = ${value'}";
  };

  mpdris2Conf = {
    Connection =
      {
        host = cfg.mpd.host;
        port = cfg.mpd.port;
        music_dir = cfg.mpd.musicDirectory;
      }
      // lib.optionalAttrs (cfg.mpd.password != null) {
        password = cfg.mpd.password;
      };

    Bling = {
      notify = cfg.notifications;
      mmkeys = cfg.multimediaKeys;
    };
  };

in
{
  meta.maintainers = [ lib.maintainers.pjones ];

  options.services.mpdris2 = {
    enable = mkEnableOption "mpDris2 the MPD to MPRIS2 bridge";
    notifications = mkEnableOption "song change notifications";
    multimediaKeys = mkEnableOption "multimedia key support";

    package = lib.mkPackageOption pkgs "mpdris2" { };

    mpd = {
      host = mkOption {
        type = types.str;
        default = config.services.mpd.network.listenAddress;
        defaultText = "config.services.mpd.network.listenAddress";
        example = "192.168.1.1";
        description = "The address where MPD is listening for connections.";
      };

      port = mkOption {
        type = types.port;
        default = config.services.mpd.network.port;
        defaultText = "config.services.mpd.network.port";
        description = ''
          The port number where MPD is listening for connections.
        '';
      };

      musicDirectory = mkOption {
        type = types.nullOr types.path;
        default = config.services.mpd.musicDirectory;
        defaultText = "config.services.mpd.musicDirectory";
        description = ''
          If set, mpDris2 will use this directory to access music artwork.
        '';
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The password to connect to MPD.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpdris2" pkgs lib.platforms.linux)
    ];

    xdg.configFile."mpDris2/mpDris2.conf".text = toIni mpdris2Conf;

    systemd.user.services.mpdris2 = {
      Install = {
        WantedBy = [ "default.target" ];
      };

      Unit = {
        Description = "MPRIS 2 support for MPD";
        After = [ "mpd.service" ];
      };

      Service = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        ExecStart = "${cfg.package}/bin/mpDris2";
        BusName = "org.mpris.MediaPlayer2.mpd";
      };
    };
  };
}
