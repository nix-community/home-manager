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

  config = mkIf cfg.enable (
    lib.mkMerge [
      { home.packages = [ cfg.package ]; }

      (mkIf pkgs.stdenv.isLinux {
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

        home.sessionVariables = {
          SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR:-/run/user/$UID}/yubikey-agent/yubikey-agent.sock";
        };
      })

      (mkIf pkgs.stdenv.isDarwin {
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

        home.sessionVariables = {
          SSH_AUTH_SOCK = "/tmp/yubikey-agent.sock";
        };
      })
    ]
  );
}
