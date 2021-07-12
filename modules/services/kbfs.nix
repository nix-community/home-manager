{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.kbfs;

in {
  options = {
    services.kbfs = {
      enable = mkEnableOption "Keybase File System";

      mountPoint = mkOption {
        type = types.str;
        default = "keybase";
        description = ''
          Mount point for the Keybase filesystem, relative to
          <envar>HOME</envar>.
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "-label kbfs" "-mount-type normal" ];
        description = ''
          Additional flags to pass to the Keybase filesystem on launch.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.kbfs" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.kbfs = {
      Unit = {
        Description = "Keybase File System";
        Requires = [ "keybase.service" ];
        After = [ "keybase.service" ];
      };

      Service = let mountPoint = ''"%h/${cfg.mountPoint}"'';
      in {
        Environment = "PATH=/run/wrappers/bin KEYBASE_SYSTEMD=1";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
        ExecStart =
          "${pkgs.kbfs}/bin/kbfsfuse ${toString cfg.extraFlags} ${mountPoint}";
        ExecStopPost = "/run/wrappers/bin/fusermount -u ${mountPoint}";
        Restart = "on-failure";
        PrivateTmp = true;
      };

      Install.WantedBy = [ "default.target" ];
    };

    home.packages = [ pkgs.kbfs ];
    services.keybase.enable = true;
  };
}
