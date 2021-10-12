{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.notify-osd;

in {
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.notify-osd = {
      enable = mkEnableOption "notify-osd";

      package = mkOption {
        type = types.package;
        default = pkgs.notify-osd;
        defaultText = literalExpression "pkgs.notify-osd";
        description = ''
          Package containing the <command>notify-osd</command> program.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.notify-osd" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.notify-osd = {
      Unit = {
        Description = "notify-osd";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${cfg.package}/bin/notify-osd";
        Restart = "on-abort";
      };
    };
  };
}
