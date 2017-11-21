{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.kbfs;

in

{
  options = {
    services.kbfs = {
      enable = mkEnableOption "Keybase File System";

      mountPoint = mkOption {
        type = types.str;
        default = "keybase";
        description = ''
          Mountpoint for the Keybase filesystem, relative to $HOME.
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [
          "-label kbfs"
          "-mount-type normal"
        ];
        description = ''
          Additional flags to pass to the Keybase filesystem on launch.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.kbfs = {
      Unit = {
        Description = "Keybase File System";
        Requires = [ "keybase.service" ];
        After = [ "keybase.service" ];
      };
  
      Service = {
        Environment = "PATH=/run/wrappers KEYBASE_SYSTEMD=1";
        ExecStartPre = ''${pkgs.coreutils}/bin/mkdir -p "%h/${cfg.mountPoint}"'';
        ExecStart = ''${pkgs.kbfs}/bin/kbfsfuse ${toString cfg.extraFlags} "%h/${cfg.mountPoint}"'';
        ExecStopPost = ''/run/wrappers/bin/fusermount -u "%h/${cfg.mountPoint}"'';
        Restart = "on-failure";
        PrivateTmp = true;
      };
  
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    services.keybase.enable = true;
  };
}
