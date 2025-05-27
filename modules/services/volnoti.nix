{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.volnoti;

in
{
  meta.maintainers = with lib.maintainers; [
    imalison
    tomodachi94
  ];

  options = {
    services.volnoti = {
      enable = lib.mkEnableOption "Volnoti volume HUD daemon";

      package = lib.mkPackageOption pkgs "volnoti" { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.volnoti" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.volnoti = {
      Unit = {
        Description = "volnoti";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} -v -n";
      };
    };
  };
}
