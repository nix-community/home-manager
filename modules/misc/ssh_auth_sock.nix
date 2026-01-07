{ config, lib, ... }:

let
  cfg = config.ssh_auth_sock;

  mkShellInitOption =
    shell:
    lib.mkOption {
      description = "Code that initializes {env}`SSH_AUTH_SOCK` in ${shell}.";
      type = lib.types.str;
    };

  initSubmodule =
    { config, ... }:
    {
      options.bash = mkShellInitOption "bash";
      options.fish = mkShellInitOption "fish";
      options.nushell = mkShellInitOption "nushell";
    };

  # Preserve $SSH_AUTH_SOCK only if it stems from a forwarded agent which
  # is the case if both $SSH_AUTH_SOCK and $SSH_CONNECTION are set.
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
{
  meta.maintainers = [ lib.maintainers.bmrips ];

  options.ssh_auth_sock.initialization = lib.mkOption {
    description = ''
      Shell-specific code to initialize {env}`SSH_AUTH_SOCK`.

      RATIONALE: {env}`SSH_AUTH_SOCK` must not be set unconditionally through
      {option}`home.sessionVariables` since its value needs to be preserved if
      it stems from a forwarded agent. Hence, this option establishes a
      centralized interface for setting {env}`SSH_AUTH_SOCK`. It checks whether
      its value has to be preserved and injects the initialization code into the
      proper {option}`programs.(bash|fish|nushell|zsh).*` options.
    '';
    example = lib.literalExpression ''
      {
        bash = "export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock";
        fish = "set -x SSH_AUTH_SOCK $HOME/.ssh/agent.sock";
        nushell = "$env.SSH_AUTH_SOCK = $HOME/.ssh/agent.sock";
      }
    '';
    default = null;
    internal = true;
    type = with lib.types; nullOr (submodule initSubmodule);
  };

  config = lib.mkIf (cfg.initialization != null) {
    # $SSH_AUTH_SOCK has to be set early since other tools rely on it
    programs.bash.profileExtra = lib.mkOrder 900 bashIntegration;
    programs.fish.shellInit = lib.mkOrder 900 fishIntegration;
    programs.nushell.extraConfig = lib.mkOrder 900 nushellIntegration;
    programs.zsh.envExtra = lib.mkOrder 900 bashIntegration;
  };
}
