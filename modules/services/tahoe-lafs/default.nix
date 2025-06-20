{
  config,
  lib,
  pkgs,
  ...
}:

{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.tahoe-lafs = {
      enable = lib.mkEnableOption "Tahoe-LAFS";
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
        ExecStart = "${pkgs.tahoelafs}/bin/tahoe run -C %h/.tahoe";
      };
    };
  };
}
