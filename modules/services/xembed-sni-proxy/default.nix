{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.xembed-sni-proxy;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    services.xembed-sni-proxy = {
      enable = lib.mkEnableOption "XEmbed SNI Proxy";

      package = lib.mkPackageOption pkgs.kdePackages "plasma-workspace" {
        pkgsText = "pkgs.kdePackages";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xembed-sni-proxy" pkgs lib.platforms.linux)
    ];

    systemd.user.services.xembed-sni-proxy = {
      Unit = {
        Description = "XEmbed SNI Proxy";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
        ExecStart = "${cfg.package}/bin/xembedsniproxy";
        Restart = "on-abort";
      };
    };
  };
}
