{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.rsibreak;

in {
  options.services.rsibreak = {

    enable = mkEnableOption "rsibreak";

  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.rsibreak" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ pkgs.rsibreak ];
    systemd.user.services.rsibreak = {
      Unit = {
        Description = "RSI break timer";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${pkgs.rsibreak}/bin/rsibreak";
      };
    };
  };
}
