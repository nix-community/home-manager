{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mpdris2;

  toIni = generators.toINI {
    mkKeyValue = key: value:
    let
      value' =
        if isBool value then (if value then "True" else "False")
        else toString value;
    in
      "${key} = ${value'}";
  };

  mpdris2Conf = {
    Connection = {
      host = cfg.mpd.host;
      port = cfg.mpd.port;
      music_dir = cfg.mpd.musicDirectory;
    };

    Bling = {
      notify = cfg.notifications;
      mmkeys = cfg.multimediaKeys;
    };
  };

in
{
  meta.maintainers = [ maintainers.pjones ];

  options.services.mpdris2 = {
    enable = mkEnableOption "mpDris2 the mpd to MPRIS2 bridge";
    notifications = mkEnableOption "Song change notifications.";
    multimediaKeys = mkEnableOption "Respond to multimedia keys.";

    package = mkOption {
      type = types.package;
      default = pkgs.mpdris2;
      example = literalExample "pkgs.mpdris2";
      description = "The mpDris2 package to use.";
    };


    mpd = {
      host = mkOption {
        type = types.str;
        default = config.services.mpd.network.listenAddress;
        example = "192.168.1.1";
        description = "The address where mpd is listening for connections.";
      };

      port = mkOption {
        type = types.ints.positive;
        default = config.services.mpd.network.port;
        description = "The port number where mpd is listening for connections.";
      };

      musicDirectory = mkOption {
        type = types.nullOr types.path;
        default = config.services.mpd.musicDirectory;
        description = ''
          If set, mpDris2 will use this directory to access music artwork.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."mpDris2/mpDris2.conf".text = toIni mpdris2Conf;

    systemd.user.services.mpdris2 = {
      Unit = {
        Description = "MPRIS 2 support for mpd";
        After = [ "graphical-session-pre.target" "mpd.service" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/mpDris2";
      };
    };
  };
}
