{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.taffybar;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.taffybar = {
      enable = lib.mkEnableOption "Taffybar";

      package = lib.mkPackageOption pkgs "taffybar" { };
    };
  };

  config = lib.mkIf config.services.taffybar.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.taffybar" pkgs lib.platforms.linux)
    ];

    systemd.user.services.taffybar = {
      Unit = {
        Description = "Taffybar desktop bar";
        PartOf = [ "tray-sni.target" ];
        After = config.lib.tray.sniWatcherAfter;
        Wants = config.lib.tray.sniWatcherWants;
        Requires = config.lib.tray.sniWatcherRequires;
        StartLimitBurst = 5;
        StartLimitIntervalSec = 10;
      };

      Service = {
        Type = "dbus";
        BusName = "org.taffybar.Bar";
        ExecStart = "${cfg.package}/bin/taffybar";
        Restart = "on-failure";
        RestartSec = "2s";
      };

      Install = {
        WantedBy = [ "tray-sni.target" ];
      };
    };

    xsession.importedVariables = [ "GDK_PIXBUF_MODULE_FILE" ];
  };
}
