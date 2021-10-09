{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.parcellite;

in {
  meta.maintainers = [ maintainers.gleber ];

  options.services.parcellite = {
    enable = mkEnableOption "Parcellite";

    package = mkOption {
      type = types.package;
      default = pkgs.parcellite;
      defaultText = literalExpression "pkgs.parcellite";
      example = literalExpression "pkgs.clipit";
      description = "Parcellite derivation to use.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.parcellite" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.parcellite = {
      Unit = {
        Description = "Lightweight GTK+ clipboard manager";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = "${cfg.package}/bin/${cfg.package.pname}";
        Restart = "on-abort";
      };
    };
  };
}
