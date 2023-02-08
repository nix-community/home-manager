{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ hm.maintainers.pltanton ];

  options = {
    services.pasystray = { enable = mkEnableOption "PulseAudio system tray"; };
  };

  config = mkIf config.services.pasystray.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.pasystray" pkgs platforms.linux)
    ];

    systemd.user.services.pasystray = {
      Unit = {
        Description = "PulseAudio system tray";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Environment =
          let toolPaths = makeBinPath [ pkgs.paprefs pkgs.pavucontrol ];
          in [ "PATH=${toolPaths}" ];
        ExecStart = "${pkgs.pasystray}/bin/pasystray";
      };
    };
  };
}
