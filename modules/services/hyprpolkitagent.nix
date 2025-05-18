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
  cfg = config.services.hyprpolkitagent;
in
{
  meta.maintainers = with maintainers; [
    bobvanderlinden
    khaneliman
  ];

  options = {
    services.hyprpolkitagent = {
      enable = mkEnableOption "Hyprland Policykit Agent";
      package = mkPackageOption pkgs "hyprpolkitagent" { };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.hyprpolkitagent = {
      Unit = {
        Description = "Hyprland PolicyKit Agent";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
      };

      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = "${cfg.package}/libexec/hyprpolkitagent";
      };
    };
  };
}
