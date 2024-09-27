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

    ${optionalString (cfg.network.listenAddress != "any")
    ''bind_to_address "${cfg.network.listenAddress}"''}
    ${optionalString (cfg.network.port != 6600)
    ''port "${toString cfg.network.port}"''}

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

      package = mkOption {
        type = types.package;
        default = pkgs.mpd;
        defaultText = "pkgs.mpd";
        description = ''
          The MPD package to run.
        '';
      };

      musicDirectory = mkOption {
        type = with types; either path str;
        defaultText = literalExpression ''
          ''${home.homeDirectory}/music    if state version < 22.11
          ''${xdg.userDirs.music}          if xdg.userDirs.enable == true
          undefined                      otherwise
        '';
        apply = toString; # Prevent copies to Nix store.
        description = ''
          The directory where mpd reads music from.

          If [](#opt-xdg.userDirs.enable) is
          `true` then the defined XDG music directory is used.
          Otherwise, you must explicitly specify a value.
        '';
      };

      playlistDirectory = mkOption {
        type = types.path;
        default = "${cfg.dataDir}/playlists";
        defaultText = "\${dataDir}/playlists";
        apply = toString; # Prevent copies to Nix store.
        description = ''
          The directory where mpd stores playlists.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra directives added to to the end of MPD's configuration
          file, {file}`mpd.conf`. Basic configuration
          like file location and uid/gid is added automatically to the
          beginning of the file. For available options see
          {manpage}`mpd.conf(5)`.
        '';
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "--verbose" ];
        description = ''
          Extra command-line arguments to pass to MPD.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "${config.xdg.dataHome}/${name}";
        defaultText = "$XDG_DATA_HOME/mpd";
        apply = toString; # Prevent copies to Nix store.
        description = ''
          The directory where MPD stores its state, tag cache,
          playlists etc.
        '';
      };

      network = {
        startWhenNeeded = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable systemd socket activation.
          '';
        };

        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          example = "any";
          description = ''
            The address for the daemon to listen on.
            Use `any` to listen on all addresses.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 6600;
          description = ''
            The TCP port on which the the daemon will listen.
          '';
        };

      };

      dbFile = mkOption {
        type = types.nullOr types.str;
        default = "${cfg.dataDir}/tag_cache";
        defaultText = "\${dataDir}/tag_cache";
        description = ''
          The path to MPD's database. If set to
          `null` the parameter is omitted from the
          configuration.
        '';
      };
    };

  };

  ###### implementation

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpd" pkgs lib.platforms.linux)
    ];

    services.mpd = mkMerge [
      (mkIf (versionAtLeast config.home.stateVersion "22.11"
        && config.xdg.userDirs.enable) {
          musicDirectory = mkOptionDefault config.xdg.userDirs.music;
        })

      (mkIf (versionOlder config.home.stateVersion "22.11") {
        musicDirectory = mkOptionDefault "${config.home.homeDirectory}/music";
      })
    ];

    systemd.user.services.mpd = {
      Unit = mkMerge [
        {
          Description = "Music Player Daemon";
          After = [ "network.target" "sound.target" ];
        }

        (mkIf cfg.network.startWhenNeeded {
          Requires = [ "mpd.socket" ];
          After = [ "mpd.socket" ];
        })
      ];

      Install = mkIf (!cfg.network.startWhenNeeded) {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
        ExecStart = "${cfg.package}/bin/mpd --no-daemon ${mpdConf} ${
            escapeShellArgs cfg.extraArgs
          }";
        Type = "notify";
        ExecStartPre = ''
          ${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/mkdir -p '${cfg.dataDir}' '${cfg.playlistDirectory}'"'';
      };
    };

    systemd.user.sockets.mpd = mkIf cfg.network.startWhenNeeded {
      Socket = {
        ListenStream = let
          listen = if cfg.network.listenAddress == "any" then
            toString cfg.network.port
          else
            "${cfg.network.listenAddress}:${toString cfg.network.port}";
        in [ listen "%t/mpd/socket" ];

        Backlog = 5;
        KeepAlive = true;
      };

      Install = { WantedBy = [ "sockets.target" ]; };
    };

    home.packages = [ cfg.package ];
  };

}
