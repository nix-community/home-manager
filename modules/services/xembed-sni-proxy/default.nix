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

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.kdePackages.plasma-workspace;
        defaultText = lib.literalExpression "pkgs.kdePackages.plasma-workspace";
        description = ''
          Package containing the {command}`xembedsniproxy`
          program.
        '';
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
