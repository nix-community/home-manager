{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.syncthing = {
      enable = mkEnableOption "Syncthing";
    };
  };

  config = mkIf config.services.syncthing.enable {
    systemd.user.services.syncthing = {
        Unit = {
          Description = "Syncthing";
          After = [ "network.target" ];
        };

        Install = {
          WantedBy = [ "default.target" ];
        };

        Service = {
          ExecStart = "${pkgs.syncthing}/bin/syncthing -no-browser";
        };
    };
  };
}
