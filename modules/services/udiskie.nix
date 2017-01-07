{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.udiskie = {
      enable = mkEnableOption "Udiskie mount daemon";
    };
  };

  config = mkIf config.services.udiskie.enable {
    systemd.user.services.udiskie = {
        Unit = {
          Description = "Udiskie mount daemon";
          Requires = [ "taffybar.service" ];
          After = [ "taffybar.service" ];
        };

        Service = {
          ExecStart = "${pkgs.pythonPackages.udiskie}/bin/udiskie -2 -A -n -s";
        };

        Install = {
          WantedBy = [ "xorg.target" ];
        };
    };
  };
}
