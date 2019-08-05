{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.slack;
in {

  options.services.slack = {
    enable = mkEnableOption "Slack chat daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.slack;
      defaultText = "pkgs.slack";
      example = literalExample "pkgs.slack";
      description = ''
        Slack derivation to use.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.slack = {
      Unit = {
        Description = "Slack chat";
        After = [ "graphical-session-pre.target" ];
      };

      Service = {
        ExecStart = "${pkgs.slack}/bin/slack --startup --rxLogging";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
