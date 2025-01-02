{ config, lib, options, pkgs, ... }:

with lib;

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

  mkSection = secname: secCfg: ''
    [${secname}]
    url      = ${secCfg.url}
    username = ${secCfg.username}
    password = {{${secname}_PASSWORD}}
    journal  = /var/lib/mpdscribble/${secname}.journal
  '';

  endpoints = concatStringsSep "\n" (mapAttrsToList mkSection cfg.endpoints);
  cfgTemplate = pkgs.writeText "mpdscribble.conf" ''
    ## This file was automatically genenrated by home-manager and will be
    ## overwritten.  Do not edit. Edit your home-manager configuration instead.

    ## mpdscribble - an audioscrobbler for the Music Player Daemon.
    ## http://mpd.wikia.com/wiki/Client:mpdscribble

    # HTTP proxy URL.
    ${optionalString (cfg.proxy != null) "proxy = ${cfg.proxy}"}

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
      (optionalString (cfg.passwordFile != null) "{{MPD_PASSWORD}}@") + cfg.host
    }

    # The port that the MPD listens on and mpdscribble should try to
    # connect to.
    port = ${toString cfg.port}

    ${endpoints}
  '';

  configFile =
    "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/mpdscribble/mpdscribble.conf";

  replaceSecret = secretFile: placeholder: targetFile:
    optionalString (secretFile != null) ''
      ${pkgs.replace-secret}/bin/replace-secret '${placeholder}' '${secretFile}' "${targetFile}" '';

  preStart = pkgs.writeShellApplication {
    name = "mpdscribble-pre-start";
    runtimeInputs = [ pkgs.replace-secret pkgs.coreutils ];
    text = ''
      configFile="${configFile}"
      mkdir -p "$(dirname "$configFile")"
      cp --no-preserve=mode,ownership -f "${cfgTemplate}" "$configFile"
      ${replaceSecret cfg.passwordFile "{{MPD_PASSWORD}}" "$configFile"}
      ${concatStringsSep "\n" (mapAttrsToList (secname: cfg:
        replaceSecret cfg.passwordFile "{{${secname}_PASSWORD}}" "$configFile")
        cfg.endpoints)}
    '';
  };

  start = pkgs.writeShellScript "mpdscribble-start" ''
    configFile="${configFile}"
    exec ${pkgs.mpdscribble}/bin/mpdscribble --no-daemon --conf "$configFile"
  '';

  localMpd = (cfg.host == "localhost" || cfg.host == "127.0.0.1");

in {
  ###### interface

  options.services.mpdscribble = {

    enable = mkEnableOption ''
      mpdscribble, an MPD client which submits info about tracks being played to
      Last.fm (formerly AudioScrobbler)
    '';

    proxy = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = ''
        HTTP proxy URL.
      '';
    };

    verbose = mkOption {
      default = 1;
      type = types.int;
      description = ''
        Log level for the mpdscribble daemon.
      '';
    };

    journalInterval = mkOption {
      default = 600;
      example = 60;
      type = types.int;
      description = ''
        How often should mpdscribble save the journal file? [seconds]
      '';
    };

    host = mkOption {
      default = (if mpdCfg.network.listenAddress != "any" then
        mpdCfg.network.listenAddress
      else
        "localhost");
      defaultText = literalExpression ''
        if config.${mpdOpt.network.listenAddress} != "any"
        then config.${mpdOpt.network.listenAddress}
        else "localhost"
      '';
      type = types.str;
      description = ''
        Host for the mpdscribble daemon to search for a mpd daemon on.
      '';
    };

    passwordFile = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = ''
        File containing the password for the mpd daemon.
      '';
    };

    port = mkOption {
      default = mpdCfg.network.port;
      defaultText = literalExpression "config.${mpdOpt.network.port}";
      type = types.port;
      description = ''
        Port for the mpdscribble daemon to search for a mpd daemon on.
      '';
    };

    endpoints = mkOption {
      type = (let
        endpoint = { name, ... }: {
          options = {
            url = mkOption {
              type = types.str;
              default = endpointUrls.${name} or "";
              description =
                "The url endpoint where the scrobble API is listening.";
            };
            username = mkOption {
              type = types.str;
              description = ''
                Username for the scrobble service.
              '';
            };
            passwordFile = mkOption {
              type = types.nullOr types.str;
              description =
                "File containing the password, either as MD5SUM or cleartext.";
            };
          };
        };
      in types.attrsOf (types.submodule endpoint));
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
          concatStringsSep ''", "'' (attrNames endpointUrls)
        }" the url is set automatically.
      '';
    };

  };

  ###### implementation

  config = mkIf cfg.enable {
    systemd.user.services.mpdscribble = {
      Unit = {
        Description = "mpdscribble mpd scrobble client";
        After = [ "network.target" ] ++ optional localMpd "mpd.service";
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
