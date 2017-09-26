{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.udiskie = {
      enable = mkEnableOption "Udiskie mount daemon";
    };
  };

  config = mkIf config.services.udiskie.enable {
    systemd.user.services.udiskie = {
        Unit = {
          Description = "Udiskie mount daemon";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.pythonPackages.udiskie}/bin/udiskie -2 -A -n -s";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
    };
  };
}
