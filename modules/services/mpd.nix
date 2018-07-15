{ config, lib, pkgs, ... }:

with lib;

let

  name = "mpd";

  cfg = config.services.mpd;

  mpdConf = pkgs.writeText "mpd.conf" ''
    music_directory     "${cfg.musicDirectory}"
    playlist_directory  "${cfg.playlistDirectory}"
    ${lib.optionalString (cfg.dbFile != null) ''
      db_file             "${cfg.dbFile}"
    ''}
    state_file          "${cfg.dataDir}/state"
    sticker_file        "${cfg.dataDir}/sticker.sql"
    log_file            "syslog"

    ${optionalString (cfg.network.listenAddress != "any") ''bind_to_address "${cfg.network.listenAddress}"''}
    ${optionalString (cfg.network.port != 6600)  ''port "${toString cfg.network.port}"''}

    ${cfg.extraConfig}
  '';

in {

  ###### interface

  options = {

    services.mpd = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable MPD, the music player daemon.
        '';
      };

     musicDirectory = mkOption {
        type = types.path;
        default = "${config.home.homeDirectory}/music";
        defaultText = "$HOME/music";
        description = ''
          The directory where mpd reads music from.
        '';
      };

      playlistDirectory = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/playlists";
        defaultText = ''''${dataDir}/playlists'';
        description = ''
          The directory where mpd stores playlists.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra directives added to to the end of MPD's configuration file,
          mpd.conf. Basic configuration like file location and uid/gid
          is added automatically to the beginning of the file. For available
          options see <literal>man 5 mpd.conf</literal>'.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "${config.xdg.dataHome}/${name}";
        defaultText = "$XDG_DATA_HOME/mpd";
        description = ''
          The directory where MPD stores its state, tag cache,
          playlists etc.
        '';
      };

     network = {

        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          example = "any";
          description = ''
            The address for the daemon to listen on.
            Use <literal>any</literal> to listen on all addresses.
          '';
        };

        port = mkOption {
          type = types.int;
          default = 6600;
          description = ''
            This setting is the TCP port that is desired for the daemon to get assigned
            to.
          '';
        };

      };

      dbFile = mkOption {
        type = types.nullOr types.str;
        default = "${cfg.dataDir}/tag_cache";
        defaultText = ''''${dataDir}/tag_cache'';
        description = ''
          The path to MPD's database. If set to <literal>null</literal> the
          parameter is omitted from the configuration.
        '';
      };
    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    systemd.user.services.mpd = {
      Unit = {
        After = [ "network.target" "sound.target" ];
        Description = "Music Player Daemon";
      };
 
      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Environment = "PATH=%h/.nix-profile/bin";
        ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon ${mpdConf}";
        Type = "notify";
        ExecStartPre = ''${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/mkdir -p '${cfg.dataDir}' '${cfg.playlistDirectory}'"'';
      };
    };
  };

}

