{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mkEnableOption mkPackageOption types literalExpression mkIf maintainers;
  cfg = config.services.lxqt-policykit-agent;
in {
  meta.maintainers = [ maintainers.bobvanderlinden ];

  options = {
    services.lxqt-policykit-agent = {
      enable = mkEnableOption "LXQT Policykit Agent";
      package = mkPackageOption pkgs [ "lxqt" "lxqt-policykit" ] { };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.lxqt-policykit-agent = {
      Unit = {
        Description = "LXQT PolicyKit Agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${cfg.package}/bin/lxqt-policykit-agent"; };
    };
  };
}
