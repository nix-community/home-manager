{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.keybase;

in {
  options.services.keybase.enable = mkEnableOption "Keybase";

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.keybase" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ pkgs.keybase ];

    systemd.user.services.keybase = {
      Unit.Description = "Keybase service";

      Service = {
        ExecStart = "${pkgs.keybase}/bin/keybase service --auto-forked";
        Restart = "on-failure";
        PrivateTmp = true;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
