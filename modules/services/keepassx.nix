{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.keepassx = {
      enable = mkEnableOption "the KeePassX password manager";
    };
  };

  config = mkIf config.services.keepassx.enable {
    systemd.user.services.keepassx = {
      Unit = {
        Description = "KeePassX password manager";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${pkgs.keepassx}/bin/keepassx -min -lock"; };
    };
  };
}
