{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.blueman-applet = {
      enable = mkEnableOption "" // {
        description = ''
          Whether to enable the Blueman applet.
          </para><para>
          Note, for the applet to work, the 'blueman' service should
          be enabled system-wide. You can enable it in the system
          configuration using
          <programlisting language="nix">
            services.blueman.enable = true;
          </programlisting>
        '';
      };
    };
  };

  config = mkIf config.services.blueman-applet.enable {
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
