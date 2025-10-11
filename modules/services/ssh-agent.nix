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
        The agent's socket; interpreted as a suffix to {env}`$XDG_RUNTIME_DIR`.
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.ssh-agent" pkgs lib.platforms.linux)
    ];

    programs =
      let
        bashIntegration = ''
          if [ -z "$SSH_AUTH_SOCK" ]; then
            export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/${cfg.socket}
          fi
        '';

        fishIntegration = ''
          if test -z "$SSH_AUTH_SOCK"
            set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/${cfg.socket}
          end
        '';

        nushellIntegration = ''
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

    systemd.user.services.ssh-agent = {
      Install.WantedBy = [ "default.target" ];
      Unit = {
        Description = "SSH authentication agent";
        Documentation = "man:ssh-agent(1)";
      };
      Service = {
        ExecStart = "${lib.getExe' cfg.package "ssh-agent"} -D -a %t/${cfg.socket}${
          lib.optionalString (
            cfg.defaultMaximumIdentityLifetime != null
          ) " -t ${toString cfg.defaultMaximumIdentityLifetime}"
        }";
        ExecStartPost = "${pkgs.writeShellScript "update-ssh-agent-env" ''
          if [ -z "$SSH_AUTH_SOCK" ]; then
            ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd "$@"
          fi
        ''} SSH_AUTH_SOCK=%t/${cfg.socket}";
      };
    };
  };
}
