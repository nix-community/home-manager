{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.caffeine;
in
{
  meta.maintainers = [ lib.maintainers.uvnikita ];

  options = {
    services.caffeine = {
      enable = lib.mkEnableOption "Caffeine service";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.caffeine" pkgs lib.platforms.linux)
    ];

    systemd.user.services.caffeine = {
      Unit = {
        Description = "caffeine";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Restart = "on-failure";
        PrivateTmp = true;
        ProtectSystem = "full";
        Type = "exec";
        Slice = "session.slice";
        ExecStart = "${pkgs.caffeine-ng}/bin/caffeine";
      };
    };
  };
}
