{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.sshAuthSock;
  socketProviderIsSocket = lib.hasSuffix ".socket" cfg.systemd.socketProviderUnit;
  orderedProviderUnits = lib.optional (!socketProviderIsSocket) cfg.systemd.socketProviderUnit;
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
          example = "$env.SSH_AUTH_SOCK = ($nu.home-dir | path join .ssh agent.sock)";
        };
        zsh = mkShellInitOption "zsh" // {
          example = "export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock";
          default = cfg.initialization.bash;
          defaultText = lib.literalExpression "config.sshAuthSock.initialization.bash";
        };
      };

    systemd.socketProviderUnit = lib.mkOption {
      description = ''
        The name of the systemd unit responsible for providing the {env}`SSH_AUTH_SOCK`.

        Services that rely on an active SSH authentication agent can reference
        this option to declare a dependency onto this unit, ensuring that the
        socket is available and being served before they start.
      '';
      example = "ssh-agent.service";
      type = lib.types.str;
    };

  };

  config =
    let
      indentNonEmptyLines = lib.flip lib.pipe [
        (lib.splitString "\n")
        (map (line: if line == "" then "" else "  ${line}"))
        lib.concatLines
        (lib.removeSuffix "\n")
      ];

      # Preserve $SSH_AUTH_SOCK if it stems from a forwarded agent which is the
      # case if both $SSH_AUTH_SOCK and $SSH_CONNECTION are set.
      mkShIntegration = code: ''
        if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then
        ${indentNonEmptyLines code}
        fi
      '';
      bashIntegration = mkShIntegration cfg.initialization.bash;
      zshIntegration = mkShIntegration cfg.initialization.zsh;
      fishIntegration = ''
        if test -z "$SSH_AUTH_SOCK"; or test -z "$SSH_CONNECTION"
        ${indentNonEmptyLines cfg.initialization.fish}
        end
      '';
      nushellIntegration =
        let
          unsetOrEmpty = var: ''("${var}" not-in $env) or ($env.${var} | is-empty)'';
        in
        ''
          if ${unsetOrEmpty "SSH_AUTH_SOCK"} or ${unsetOrEmpty "SSH_CONNECTION"} {
          ${indentNonEmptyLines cfg.initialization.nushell}
          }
        '';
    in
    lib.mkIf cfg.enable {
      # $SSH_AUTH_SOCK has to be set early since other tools rely on it
      programs.bash.profileExtra = lib.mkOrder 900 bashIntegration;
      programs.fish.shellInit = lib.mkOrder 900 fishIntegration;
      programs.nushell.extraConfig = lib.mkOrder 900 nushellIntegration;
      programs.zsh = {
        # Mimic how `home.sessionVariablesPackage` is sourced in the Zsh module
        # to ensure that session variables which SSH_AUTH_SOCK might rely on are
        # set.
        envExtra = lib.mkOrder 900 ''
          if [[ ! -o login ]]; then
          ${indentNonEmptyLines zshIntegration}
          fi
        '';
        profileExtra = lib.mkOrder 900 zshIntegration;
      };

      # Replace this service by an environment generator as soon as they are
      # available per-user. See https://github.com/systemd/systemd/issues/32423
      # for more information.
      systemd.user.services.set-SSH_AUTH_SOCK = {
        Unit = {
          Description = "Sets SSH_AUTH_SOCK in the D-BUS daemon and systemd";
          # Socket units are ordered before sockets.target by systemd. Ordering
          # this service before them creates a cycle through basic.target.
          Before = orderedProviderUnits;
        };
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "set-SSH_AUTH_SOCK" ''
            ${bashIntegration}
            ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd SSH_AUTH_SOCK
          '';
        };
        Install.WantedBy = [
          "default.target"
        ]
        ++ orderedProviderUnits;
      };
    };
}
