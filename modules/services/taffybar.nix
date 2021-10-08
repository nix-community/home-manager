{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.taffybar;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.taffybar = {
      enable = mkEnableOption "Taffybar";

      package = mkOption {
        default = pkgs.taffybar;
        defaultText = literalExpression "pkgs.taffybar";
        type = types.package;
        example = literalExpression "pkgs.taffybar";
        description = "The package to use for the Taffybar binary.";
      };
    };
  };

  config = mkIf config.services.taffybar.enable {
    systemd.user.services.taffybar = {
      Unit = {
        Description = "Taffybar desktop bar";
        PartOf = [ "tray.target" ];
      };

      Service = {
        Type = "dbus";
        BusName = "org.taffybar.Bar";
        ExecStart = "${cfg.package}/bin/taffybar";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ "tray.target" ]; };
    };

    xsession.importedVariables = [ "GDK_PIXBUF_MODULE_FILE" ];
  };
}
