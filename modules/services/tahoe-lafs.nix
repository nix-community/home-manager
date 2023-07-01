{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.tahoe-lafs = { enable = mkEnableOption "Tahoe-LAFS"; };
  };

  config = mkIf config.services.tahoe-lafs.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.tahoe-lafs" pkgs platforms.linux)
    ];

    systemd.user.services.tahoe-lafs = {
      Unit = { Description = "Tahoe-LAFS"; };

      Service = { ExecStart = "${pkgs.tahoelafs}/bin/tahoe run -C %h/.tahoe"; };
    };
  };
}
