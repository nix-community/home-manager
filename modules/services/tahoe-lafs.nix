{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tahoe-lafs;
in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.tahoe-lafs = {
      enable = lib.mkEnableOption "Tahoe-LAFS";

      package = lib.mkPackageOption pkgs "tahoelafs" { };
    };
  };

  config = lib.mkIf config.services.tahoe-lafs.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.tahoe-lafs" pkgs lib.platforms.linux)
    ];

    systemd.user.services.tahoe-lafs = {
      Unit = {
        Description = "Tahoe-LAFS";
      };

      Service = {
        ExecStart = "${lib.getExe' cfg.package "tahoe"} run -C %h/.tahoe";
      };
    };
  };
}
