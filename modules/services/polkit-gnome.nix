{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkIf
    maintainers
    ;
  cfg = config.services.polkit-gnome;
in
{
  meta.maintainers = [ maintainers.bobvanderlinden ];

  options = {
    services.polkit-gnome = {
      enable = mkEnableOption "GNOME Policykit Agent";
      package = mkPackageOption pkgs "polkit_gnome" { };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.polkit-gnome = {
      Unit = {
        Description = "GNOME PolicyKit Agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/libexec/polkit-gnome-authentication-agent-1";
      };
    };
  };
}
