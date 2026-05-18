{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = config.services.yubikey-agent;

in
{
  meta.maintainers = [ lib.maintainers.cmacrae ];

  options.services.yubikey-agent = {
    enable = lib.mkEnableOption "Seamless ssh-agent for YubiKeys";

    package = lib.mkPackageOption pkgs "yubikey-agent" { };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    sshAuthSock.initialization =
      let
        darwinSocket = "/tmp/yubikey-agent.sock";
        linuxSocketSuffix = "yubikey-agent/yubikey-agent.sock";
      in
      {
        bash = ''export SSH_AUTH_SOCK="${
          if pkgs.stdenv.isDarwin then
            darwinSocket
          else
            "\${XDG_RUNTIME_DIR:-/run/user/$UID}/${linuxSocketSuffix}"
        }"'';

        fish =
          if pkgs.stdenv.isDarwin then
            ''
              set -x SSH_AUTH_SOCK ${darwinSocket}
            ''
          else
            ''
              set -l runtime_dir "$XDG_RUNTIME_DIR"
              test -n "$runtime_dir"; or set runtime_dir /run/user/(id -u)
              set -x SSH_AUTH_SOCK "$runtime_dir/${linuxSocketSuffix}"
            '';

        nushell = "$env.SSH_AUTH_SOCK = ${
          if pkgs.stdenv.isDarwin then
            darwinSocket
          else
            ''$"($env.XDG_RUNTIME_DIR? | default $"/run/user/(id -u)")/${linuxSocketSuffix}"''
        }";
      };

    systemd.user.services.yubikey-agent = {
      Unit = {
        Description = "Seamless ssh-agent for YubiKeys";
        Documentation = "https://github.com/FiloSottile/yubikey-agent";
        Requires = "yubikey-agent.socket";
        After = "yubikey-agent.socket";
        RefuseManualStart = true;
      };

      Service = {
        ExecStart = "${cfg.package}/bin/yubikey-agent -l %t/yubikey-agent/yubikey-agent.sock";
        Type = "simple";
        # /run/user/$UID for the socket
        ReadWritePaths = [ "%t" ];
      };
    };

    systemd.user.sockets.yubikey-agent = {
      Unit = {
        Description = "Unix domain socket for Yubikey SSH agent";
        Documentation = "https://github.com/FiloSottile/yubikey-agent";
      };

      Socket = {
        ListenStream = "%t/yubikey-agent/yubikey-agent.sock";
        RuntimeDirectory = "yubikey-agent";
        SocketMode = "0600";
        DirectoryMode = "0700";
      };

      Install = {
        WantedBy = [ "sockets.target" ];
      };
    };

    launchd.agents.yubikey-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/yubikey-agent"
          "-l"
          "/tmp/yubikey-agent.sock"
        ];

        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        Sockets = {
          Listener = {
            SockPathName = "/tmp/yubikey-agent.sock";
            SockPathMode = 384; # 0600 in decimal
          };
        };
      };
    };
  };
}
