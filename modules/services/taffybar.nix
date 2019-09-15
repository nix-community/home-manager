{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.taffybar;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.taffybar = {
      enable = mkEnableOption "Taffybar";

      package = mkOption {
        default = pkgs.taffybar;
        defaultText = literalExample "pkgs.taffybar";
        type = types.package;
        example = literalExample "pkgs.taffybar";
        description = "The package to use for the Taffybar binary.";
      };
    };
  };

  config = mkIf config.services.taffybar.enable {
    systemd.user.services.taffybar = {
      Unit = {
        Description = "Taffybar desktop bar";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/taffybar";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    xsession.importedVariables = [ "GDK_PIXBUF_MODULE_FILE" ];
  };
}
