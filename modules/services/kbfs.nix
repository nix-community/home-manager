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
          Mount point for the Keybase filesystem, relative to
          <envar>HOME</envar>.
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

      fusermountPath = mkOption {
        type = types.str;
        default = "/run/wrappers/bin";
        example = "/usr/bin";
        description = ''
          Path to the directory containing the <citerefentry>
            <refentrytitle>fusermount</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry> binary for the system. The binary should be
          suid root or otherwise executable by the home user.
          </para><para>
          This option should be customized on non-NixOS systems.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.kbfs = {
      Unit = {
        Description = "Keybase File System";
        Requires = [ "kbfs.socket" ];
        Wants = [ "keybase.service" ];
      };

      Service =
        let
          mountPoint = "\"%h/${cfg.mountPoint}\"";
        in {
          Type = "notify";
          Environment = [
            "KEYBASE_SYSTEMD=1"
            "PATH=${cfg.fusermountPath}:${pkgs.coreutils}/bin"
          ];
          EnvironmentFile = [
            "-%E/keybase/keybase.autogen.env"
            "-%E/keybase/keybase.env"
          ];
          PIDFile = "%t/keybase/kbfsd.pid";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}"
            "-${cfg.fusermountPath}/fusermount -uz ${mountPoint}"
          ];
          ExecStart = "${pkgs.kbfs}/bin/kbfsfuse ${toString cfg.extraFlags} ${mountPoint}";
          ExecStopPost = "-${cfg.fusermountPath}/fusermount -uz ${mountPoint}";
          Restart = "on-failure";
        };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    systemd.user.sockets.kbfs = {
      Unit = {
        Description = "Socket for Keybase File System";
      };

      Socket = {
        ListenStream = "%t/keybase/kbfsd.sock";
      };

      Install = {
        WantedBy = [ "sockets.target" ];
      };
    };

    home.packages = [ pkgs.kbfs ];
    services.keybase.enable = true;
  };
}
