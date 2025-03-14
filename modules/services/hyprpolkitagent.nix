{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mkEnableOption mkPackageOption types literalExpression mkIf maintainers;
  cfg = config.services.hyprpolkitagent;
in {
  meta.maintainers = [ maintainers.bobvanderlinden ];

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
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${cfg.package}/libexec/hyprpolkitagent"; };
    };
  };
}
