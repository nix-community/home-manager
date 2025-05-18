{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.mpris-proxy;

in
{
  meta.maintainers = [ lib.maintainers.thibautmarty ];

  options.services.mpris-proxy.enable = lib.mkEnableOption "a proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players";

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpris-proxy" pkgs lib.platforms.linux)
    ];

    systemd.user.services.mpris-proxy = {
      Unit = {
        Description = "Proxy forwarding Bluetooth MIDI controls via MPRIS2 to control media players";
        BindsTo = [ "bluetooth.target" ];
        After = [ "bluetooth.target" ];
      };

      Install.WantedBy = [ "bluetooth.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
      };
    };
  };
}
