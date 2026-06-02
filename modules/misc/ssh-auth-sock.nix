{ config, lib, ... }:

let
  cfg = config.sshAuthSock;
in
{
  meta.maintainers = [ lib.maintainers.bmrips ];

  options.sshAuthSock = {

    enable = lib.mkEnableOption "" // {
      description = ''
        Whether to set {env}`SSH_AUTH_SOCK` in shells, systemd, and the D-BUS daemon
        unless it was already defined through SSH agent forwarding.

        Typically, this module will be implicitly enabled and configured by SSH
        agent modules.
      '';
    };

    initialization =
      let
        mkShellInitOption =
          shell:
          lib.mkOption {
            description = "Code that initializes {env}`SSH_AUTH_SOCK` in ${shell}.";
            type = lib.types.str;
          };
      in
      {
        bash = mkShellInitOption "bash" // {
          example = "export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock";
        };
        fish = mkShellInitOption "fish" // {
          example = "set -x SSH_AUTH_SOCK $HOME/.ssh/agent.sock";
        };
        nushell = mkShellInitOption "nushell" // {
          example = "$env.SSH_AUTH_SOCK = $HOME/.ssh/agent.sock";
        };
      };

  };

  config =
    let
      # Preserve $SSH_AUTH_SOCK if it stems from a forwarded agent which is the
      # case if both $SSH_AUTH_SOCK and $SSH_CONNECTION are set.
      bashIntegration = ''
        if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then
          ${cfg.initialization.bash}
        fi
      '';
      fishIntegration = ''
        if test -z "$SSH_AUTH_SOCK"; or test -z "$SSH_CONNECTION"
          ${cfg.initialization.fish}
        end
      '';
      nushellIntegration =
        let
          unsetOrEmpty = var: ''("${var}" not-in $env) or ($env.${var} | is-empty)'';
        in
        ''
          if ${unsetOrEmpty "SSH_AUTH_SOCK"} or ${unsetOrEmpty "SSH_CONNECTION"} {
            ${cfg.initialization.nushell}
          }
        '';
    in
    lib.mkIf cfg.enable {
      # $SSH_AUTH_SOCK has to be set early since other tools rely on it
      programs.bash.profileExtra = lib.mkOrder 900 bashIntegration;
      programs.fish.shellInit = lib.mkOrder 900 fishIntegration;
      programs.nushell.extraConfig = lib.mkOrder 900 nushellIntegration;
      programs.zsh.envExtra = lib.mkOrder 900 bashIntegration;
    };
}
