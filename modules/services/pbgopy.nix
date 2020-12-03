{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.pbgopy;
  package = pkgs.pbgopy;
in {
  meta.maintainers = [ maintainers.ivar ];

  options.services.pbgopy = {
    enable = mkEnableOption "pbgopy";

    cache.ttl = mkOption {
      type = types.str;
      default = "24h";
      example = "10m";
      description = ''
        The TTL for the cache. Use <literal>"0s"</literal> to disable it.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    systemd.user.services.pbgopy = {
      Unit = {
        Description = "pbgopy server for sharing the clipboard between devices";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${package}/bin/pbgopy serve --ttl ${cfg.cache.ttl}";
        Restart = "on-abort";
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
