{ config, lib, options, pkgs, ... }:

let
  cfg = config.services.mpdscribble;
  mpdCfg = config.services.mpd;
  mpdOpt = options.services.mpd;

  endpointUrls = {
    "last.fm" = "http://post.audioscrobbler.com";
    "libre.fm" = "http://turtle.libre.fm";
    "jamendo" = "http://postaudioscrobbler.jamendo.com";
    "listenbrainz" = "http://proxy.listenbrainz.org";
  };
in {
  options.services.mpdscribble = {

    enable = lib.mkEnableOption ''
      mpdscribble, an MPD client which submits info about tracks being played to
      Last.fm (formerly AudioScrobbler)
    '';

    proxy = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
      description = ''
        HTTP proxy URL.
      '';
    };

    verbose = lib.mkOption {
      default = 1;
      type = lib.types.int;
      description = ''
        Log level for the mpdscribble daemon.
      '';
    };

    journalInterval = lib.mkOption {
      default = 600;
      example = 60;
      type = lib.types.int;
      description = ''
        How often should mpdscribble save the journal file? [seconds]
      '';
    };

    host = lib.mkOption {
      default = (if mpdCfg.network.listenAddress != "any" then
        mpdCfg.network.listenAddress
      else
        "localhost");
      defaultText = lib.literalExpression ''
        if config.${mpdOpt.network.listenAddress} != "any"
        then config.${mpdOpt.network.listenAddress}
        else "localhost"
      '';
      type = lib.types.str;
      description = ''
        Host for the mpdscribble daemon to search for a mpd daemon on.
      '';
    };

    package = lib.mkPackageOption pkgs "mpdscribble" { };

    passwordFile = lib.mkOption {
      default = null;
      type = lib.types.nullOr lib.types.str;
      description = ''
        File containing the password for the mpd daemon.
      '';
    };

    port = lib.mkOption {
      default = mpdCfg.network.port;
      defaultText = lib.literalExpression "config.${mpdOpt.network.port}";
      type = lib.types.port;
      description = ''
        Port for the mpdscribble daemon to search for a mpd daemon on.
      '';
    };

    endpoints = lib.mkOption {
      type = let
        endpoint = { name, ... }: {
          options = {
            url = lib.mkOption {
              type = lib.types.str;
              default = endpointUrls.${name} or "";
              description =
                "The url endpoint where the scrobble API is listening.";
            };
            username = lib.mkOption {
              type = lib.types.str;
              description = ''
                Username for the scrobble service.
              '';
            };
            passwordFile = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description =
                "File containing the password, either as MD5SUM or cleartext.";
            };
          };
        };
      in lib.types.attrsOf (lib.types.submodule endpoint);
      default = { };
      example = {
        "last.fm" = {
          username = "foo";
          passwordFile = "/run/secrets/lastfm_password";
        };
      };
      description = ''
        Endpoints to scrobble to.
        If the endpoint is one of "${
          lib.concatStringsSep ''", "'' (builtins.attrNames endpointUrls)
        }" the url is set automatically.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpdscribble" pkgs
        lib.platforms.linux)
    ];
    systemd.user.services.mpdscribble = let
      localMpd = (cfg.host == "localhost" || cfg.host == "127.0.0.1");

      mkSection = secname: secCfg: ''
        [${secname}]
        url      = ${secCfg.url}
        username = ${secCfg.username}
        password = {{${secname}_PASSWORD}}
        journal  = /var/lib/mpdscribble/${secname}.journal
      '';

      endpoints =
        lib.concatStringsSep "\n" (lib.mapAttrsToList mkSection cfg.endpoints);
      cfgTemplate = pkgs.writeText "mpdscribble.conf" ''
        ## This file was automatically genenrated by home-manager and will be
        ## overwritten.  Do not edit. Edit your home-manager configuration instead.

        ## mpdscribble - an audioscrobbler for the Music Player Daemon.
        ## http://mpd.wikia.com/wiki/Client:mpdscribble

        # HTTP proxy URL.
        ${lib.optionalString (cfg.proxy != null) "proxy = ${cfg.proxy}"}

        # The location of the mpdscribble log file.  The special value
        # "syslog" makes mpdscribble use the local syslog daemon.  On most
        # systems, log messages will appear in /var/log/daemon.log then.
        # "-" means log to stderr (the current terminal).
        log = -

        # How verbose mpdscribble's logging should be.  Default is 1.
        verbose = ${toString cfg.verbose}

        # How often should mpdscribble save the journal file? [seconds]
        journal_interval = ${toString cfg.journalInterval}

        # The host running MPD, possibly protected by a password
        # ([PASSWORD@]HOSTNAME).
        host = ${
          (lib.optionalString (cfg.passwordFile != null) "{{MPD_PASSWORD}}@")
          + cfg.host
        }

        # The port that the MPD listens on and mpdscribble should try to
        # connect to.
        port = ${toString cfg.port}

        ${endpoints}
      '';

      configFile =
        "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mpdscribble/mpdscribble.conf";

      replaceSecret = secretFile: placeholder: targetFile:
        lib.optionalString (secretFile != null) ''
          ${pkgs.replace-secret}/bin/replace-secret '${placeholder}' '${secretFile}' "${targetFile}"
        '';

      preStart = pkgs.writeShellApplication {
        name = "mpdscribble-pre-start";
        runtimeInputs = [ pkgs.replace-secret pkgs.coreutils ];
        text = ''
          configFile="${configFile}"
          mkdir -p "$(dirname "$configFile")"
          cp --no-preserve=mode,ownership -f "${cfgTemplate}" "$configFile"
          ${replaceSecret cfg.passwordFile "{{MPD_PASSWORD}}" "$configFile"}
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (secname: cfg:
            replaceSecret cfg.passwordFile "{{${secname}_PASSWORD}}"
            "$configFile") cfg.endpoints)}
        '';
      };

      start = pkgs.writeShellScript "mpdscribble-start" ''
        configFile="${configFile}"
        exec "${lib.getExe cfg.package}" --no-daemon --conf "$configFile"
      '';

    in {
      Unit = {
        Description = "mpdscribble mpd scrobble client";
        After = [ "network.target" ] ++ lib.optional localMpd "mpd.service";
      };
      Install.WantedBy = [ "default.target" ];
      Service = {
        StateDirectory = "mpdscribble";
        RuntimeDirectory = "mpdscribble";
        RuntimeDirectoryMode = "700";
        # TODO use LoadCredential= instead of running preStart with full privileges?
        ExecStartPre = "+${preStart}/bin/mpdscribble-pre-start";
        ExecStart = "${start}";
      };
    };
  };

  meta.maintainers = [ lib.hm.maintainers.msyds ];
}
