{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ssh-agent;
in
{
  meta.maintainers = [
    lib.maintainers.bmrips
    lib.hm.maintainers.lheckemann
  ];

  options.services.ssh-agent = {
    enable = lib.mkEnableOption "OpenSSH private key agent";

    package = lib.mkPackageOption pkgs "openssh" { };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "ssh-agent";
      example = "ssh-agent/socket";
      description = ''
        The agent's socket; interpreted as a suffix to {env}`$XDG_RUNTIME_DIR`
        on Linux and `$(getconf DARWIN_USER_TEMP_DIR)` on macOS.
      '';
    };

    defaultMaximumIdentityLifetime = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 3600;
      description = ''
        Set a default value for the maximum lifetime in seconds of identities added to the agent.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs =
          let
            socketPath =
              if pkgs.stdenv.isDarwin then
                "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"
              else
                "$XDG_RUNTIME_DIR/${cfg.socket}";

            bashIntegration = ''
              if [ -z "$SSH_AUTH_SOCK" ]; then
                export SSH_AUTH_SOCK=${socketPath}
              fi
            '';

            fishIntegration = ''
              if test -z "$SSH_AUTH_SOCK"
                set -x SSH_AUTH_SOCK ${socketPath}
              end
            '';

            nushellIntegration =
              if pkgs.stdenv.isDarwin then
                ''
                  if "SSH_AUTH_SOCK" not-in $env {
                    $env.SSH_AUTH_SOCK = $"(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"
                  }
                ''
              else
                ''
                  if "SSH_AUTH_SOCK" not-in $env {
                    $env.SSH_AUTH_SOCK = $"($env.XDG_RUNTIME_DIR)/${cfg.socket}"
                  }
                '';
          in
          {
            bash.initExtra = lib.mkIf cfg.enableBashIntegration bashIntegration;

            zsh.initContent = lib.mkIf cfg.enableZshIntegration bashIntegration;

            fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration fishIntegration;

            nushell.extraConfig = lib.mkIf cfg.enableNushellIntegration nushellIntegration;
          };
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        systemd.user.services.ssh-agent = {
          Install.WantedBy = [ "default.target" ];
          Unit = {
            Description = "SSH authentication agent";
            Documentation = "man:ssh-agent(1)";
          };
          Service.ExecStart = "${lib.getExe' cfg.package "ssh-agent"} -D -a %t/${cfg.socket}${
            lib.optionalString (
              cfg.defaultMaximumIdentityLifetime != null
            ) " -t ${toString cfg.defaultMaximumIdentityLifetime}"
          }";
        };
      })

      (lib.mkIf pkgs.stdenv.isDarwin {
        launchd.agents.ssh-agent = {
          enable = true;
          config = {
            ProgramArguments = [
              (lib.getExe pkgs.bash)
              "-c"
              ''${lib.getExe' cfg.package "ssh-agent"} -D -a "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"${
                lib.optionalString (
                  cfg.defaultMaximumIdentityLifetime != null
                ) " -t ${toString cfg.defaultMaximumIdentityLifetime}"
              }''
            ];
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
            RunAtLoad = true;
          };
        };
      })
    ]
  );
}
