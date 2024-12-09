{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkOption mkPackageOption mkEnableOption types;

  cfg = config.services.arrpc;
in {
  meta.maintainers = [ lib.maintainers.NotAShelf ];

  options.services.arrpc = {
    enable = mkEnableOption "arrpc";
    package = mkPackageOption pkgs "arrpc" { };

    systemdTarget = mkOption {
      type = types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.arRPC = {
      Unit = {
        Description =
          "Discord Rich Presence for browsers, and some custom clients";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "always";
      };

      Install.WantedBy = [ cfg.systemdTarget ];
    };
  };
}
