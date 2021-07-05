{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.caffeine;

in {
  meta.maintainers = [ maintainers.uvnikita ];

  options = {
    services.caffeine = { enable = mkEnableOption "Caffeine service"; };
  };

  config = mkIf cfg.enable {
    systemd.user.services.caffeine = {
      Unit = { Description = "caffeine"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Restart = "on-failure";
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = "yes";
        Type = "exec";
        Slice = "session.slice";
        ExecStart = "${pkgs.caffeine-ng}/bin/caffeine";
      };
    };
  };
}
