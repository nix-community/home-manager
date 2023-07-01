{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.blueman-applet = {
      enable = mkEnableOption "" // {
        description = ''
          Whether to enable the Blueman applet.

          Note that for the applet to work, the `blueman` service should
          be enabled system-wide. You can enable it in the system
          configuration using
          ```nix
          services.blueman.enable = true;
          ```
        '';
      };
    };
  };

  config = mkIf config.services.blueman-applet.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.blueman-applet" pkgs
        platforms.linux)
    ];

    systemd.user.services.blueman-applet = {
      Unit = {
        Description = "Blueman applet";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${pkgs.blueman}/bin/blueman-applet"; };
    };
  };
}
