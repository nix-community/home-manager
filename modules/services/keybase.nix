{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.keybase;

in

{
  options = {
    services.keybase = {
      enable = mkEnableOption "Keybase";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.keybase ];

    systemd.user.services.keybase = {
      Unit = {
        Description = "Keybase core service";
        Requires = [ "keybase.socket" ];
      };

      Service = {
        Type = "notify";
        Environment = [
          "KEYBASE_SERVICE_TYPE=systemd"
          "KEYBASE_SYSTEMD=1"
        ];
        EnvironmentFile = [
          "-%E/keybase/keybase.autogen.env"
          "-%E/keybase/keybase.env"
        ];
        PIDFile = "%t/keybase/keybased.pid";
        ExecStart = "${pkgs.keybase}/bin/keybase service";
        Restart = "on-failure";
      };
    };

    systemd.user.sockets.keybase = {
      Unit = {
        Description = "Socket for the Keybase core service";
      };

      Socket = {
        ListenStream = "%t/keybase/keybased.sock";
      };

      Install = {
        WantedBy = [ "sockets.target" ];
      };
    };
  };
}
