{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.keepassx = {
      enable = mkEnableOption "the KeePassX password manager";
    };
  };

  config = mkIf config.services.keepassx.enable {
    systemd.user.services.keepassx = {
        Unit = {
          Description = "KeePassX password manager";
        };

        Install = {
          WantedBy = [ "xorg.target" ];
        };

        Service = {
          ExecStart = "${pkgs.keepassx}/bin/keepassx -min -lock";
        };
    };
  };
}
