{ config, lib, pkgs, ... }:
with lib; {
  meta.maintainers = [ hm.maintainers.bobvanderlinden ];

  options.services.lxqt-policykit-agent = {
    enable = mkEnableOption "LXQT Policykit Agent";
    package = mkOption {
      type = types.package;
      default = pkgs.lxqt.lxqt-policykit;
      defaultText = literalExample "pkgs.lxqt.lxqt-policykit";
      description = ''
        LXQT Policykit package to use
      '';
    };
  };

  config = mkIf config.services.lxqt-policykit-agent.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.lxqt-policykit-agent" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.lxqt-policykit-agent = {
      Unit = {
        Description = "LXQT PolicyKit Agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart =
          "${config.services.lxqt-policykit-agent.package}/bin/lxqt-policykit-agent";
      };
    };
  };
}
