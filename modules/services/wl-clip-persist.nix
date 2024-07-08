{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption mkPackageOption;
  cfg = config.services.wl-cilp-persist;
in {
  meta.maintainers = []; # TODO: add maintainer

  options.services.wl-clip-persist = {
    enable = mkEnableOption "wl-clip-persist";
    package = mkPackageOption pkgs "wl-clip-persist"; # TODO: make it global
    systemd = mkEnableOption "systemd service for wl-clip-persist" // mkOption {default = true;};
  };

  config = mkIf cfg.enable {
    systemd.user = mkIf cfg.systemd {
      services.wl-clip-persist = {
        Unit = {
          Description = "Persistent clipboard for Wayland";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };

        Service = {
          ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard both";
          Restart = "always";
        };

        Install.WantedBy = ["graphical-session.target"];
      };
    };
  };
}
