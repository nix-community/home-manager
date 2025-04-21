{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.network-manager-applet;

in
{
  meta.maintainers = [
    lib.maintainers.rycee
    lib.maintainers.midirhee12
  ];

  options = {
    services.network-manager-applet = {
      enable = lib.mkEnableOption "the Network Manager applet (nm-applet)";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.network-manager-applet" pkgs lib.platforms.linux)
    ];

    # The package provides some icons that are good to have available.
    xdg.systemDirs.data = [ "${pkgs.networkmanagerapplet}/share" ];

    systemd.user.services.network-manager-applet = {
      Unit = {
        Description = "Network Manager applet";
        Requires = [ "tray.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = toString (
          [ "${pkgs.networkmanagerapplet}/bin/nm-applet" ]
          ++ lib.optional config.xsession.preferStatusNotifierItems "--indicator"
        );
      };
    };
  };
}
