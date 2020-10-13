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
      defaultText = literalExample "pkgs.parcellite";
      example = literalExample "pkgs.clipit";
      description = "Parcellite derivation to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.parcellite = {
      Unit = {
        Description = "Lightweight GTK+ clipboard manager";
        After = [ "graphical-session-pre.target" ];
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
