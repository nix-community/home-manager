{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.compton = {
      enable = mkEnableOption "Compton X11 compositor";
    };
  };

  config = mkIf config.services.compton.enable {
    systemd.user.services.compton = {
        Unit = {
          Description = "Compton X11 compositor";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.compton}/bin/compton";
        };
    };
  };
}
