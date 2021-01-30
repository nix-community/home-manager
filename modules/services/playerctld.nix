{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.playerctld;

in {
  meta.maintainers = [ maintainers.fendse ];

  options.services.playerctld = {
    enable = mkEnableOption "playerctld daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.playerctl;
      defaultText = literalExample "pkgs.playerctl";
      description = "The playerctl package to use.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.playerctld = {
      Unit.Description = "MPRIS media player daemon";

      Install.WantedBy = [ "default.target" ];

      Service = {
        ExecStart = "${cfg.package}/bin/playerctld";
        Type = "dbus";
        BusName = "org.mpris.MediaPlayer2.playerctld";
      };
    };
  };
}
