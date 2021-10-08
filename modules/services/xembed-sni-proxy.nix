{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xembed-sni-proxy;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.xembed-sni-proxy = {
      enable = mkEnableOption "XEmbed SNI Proxy";

      package = mkOption {
        type = types.package;
        default = pkgs.plasma-workspace;
        defaultText = literalExpression "pkgs.plasma-workspace";
        description = ''
          Package containing the <command>xembedsniproxy</command>
          program.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xembed-sni-proxy" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.xembed-sni-proxy = {
      Unit = {
        Description = "XEmbed SNI Proxy";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${cfg.package}/bin/xembedsniproxy";
        Restart = "on-abort";
      };
    };
  };
}
