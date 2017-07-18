{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.syncthing = {
      enable = mkEnableOption "Syncthing continuous file synchronization";
    };
  };

  config = mkIf config.services.syncthing.enable {
    systemd.user.services.syncthing = {
      Unit = {
        Description = "Syncthing - Open Source Continuous File Synchronization";
        Documentation = "man:syncthing(1)";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = "${pkgs.syncthing}/bin/syncthing -no-browser -no-restart -logflags=0";
        Restart = "on-failure";
        SuccessExitStatus = [ 3 4 ];
        RestartForceExitStatus = [ 3 4 ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
