{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xsettingsd;

in {
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.xsettingsd = {
      enable = mkEnableOption "xsettingsd";

      package = mkOption {
        type = types.package;
        default = pkgs.xsettingsd;
        defaultText = literalExample "pkgs.xsettingsd";
        description = ''
          Package containing the <command>xsettingsd</command> program.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xsettingsd" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.xsettingsd = {
      Unit = {
        Description = "xsettingsd";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${cfg.package}/bin/xsettingsd";
        Restart = "on-abort";
      };
    };
  };
}
