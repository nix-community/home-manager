{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.pbgopy;
  package = pkgs.pbgopy;

  commandLine = concatStringsSep " " ([
    "${package}/bin/pbgopy serve"
    "--port ${toString cfg.port}"
    "--ttl ${cfg.cache.ttl}"
  ] ++ optional (cfg.httpAuth != null)
    "--basic-auth ${escapeShellArg cfg.httpAuth}");

in {
  meta.maintainers = [ maintainers.ivar ];

  options.services.pbgopy = {
    enable = mkEnableOption "pbgopy";

    port = mkOption {
      type = types.port;
      default = 9090;
      example = 8080;
      description = ''
        The port to host the pbgopy server on.
      '';
    };

    cache.ttl = mkOption {
      type = types.str;
      default = "24h";
      example = "10m";
      description = ''
        The TTL for the cache. Use <literal>"0s"</literal> to disable it.
      '';
    };

    httpAuth = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "user:pass";
      description = ''
        Basic HTTP authentication's username and password. Both the username and
        password are escaped.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pbgopy" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ package ];

    systemd.user.services.pbgopy = {
      Unit = {
        Description = "pbgopy server for sharing the clipboard between devices";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = commandLine;
        Restart = "on-abort";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
