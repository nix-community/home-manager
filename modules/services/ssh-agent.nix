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

    pkcs11Whitelist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''[ "''${pkgs.tpm2-pkcs11}/lib/*" ]'';
      description = ''
        Specify a list of approved path patterns for PKCS#11 and FIDO authenticator middleware libraries. When using the -s or -S options with {manpage}`ssh-add(1)`, only libraries matching these patterns will be accepted.

        See {manpage}`ssh-agent(1)`.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };
  };

  config = lib.mkIf cfg.enable {

    programs =
      let
        socketPath =
          if pkgs.stdenv.isDarwin then
            "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"
          else
            "$XDG_RUNTIME_DIR/${cfg.socket}";

        # Preserve $SSH_AUTH_SOCK only if it stems from a forwarded agent which
        # is the case if both $SSH_AUTH_SOCK and $SSH_CONNECTION are set.
        bashIntegration = ''
          if [ -z "$SSH_AUTH_SOCK" -o -z "$SSH_CONNECTION" ]; then
            export SSH_AUTH_SOCK=${socketPath}
          fi
        '';
        fishIntegration = ''
          if test -z "$SSH_AUTH_SOCK"; or test -z "$SSH_CONNECTION"
            set -x SSH_AUTH_SOCK ${socketPath}
          end
        '';
        nushellIntegration =
          let
            unsetOrEmpty = var: ''("${var}" not-in $env) or ($env.${var} | is-empty)'';
            socketPath =
              if pkgs.stdenv.isDarwin then
                ''$"(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"''
              else
                ''$"($env.XDG_RUNTIME_DIR)/${cfg.socket}"'';
          in
          ''
            if ${unsetOrEmpty "SSH_AUTH_SOCK"} or ${unsetOrEmpty "SSH_CONNECTION"} {
              $env.SSH_AUTH_SOCK = ${socketPath}
            }
          '';
      in
      {
        # $SSH_AUTH_SOCK has to be set early since other tools rely on it
        bash.profileExtra = lib.mkIf cfg.enableBashIntegration (lib.mkOrder 900 bashIntegration);
        fish.shellInit = lib.mkIf cfg.enableFishIntegration (lib.mkOrder 900 fishIntegration);
        nushell.extraConfig = lib.mkIf cfg.enableNushellIntegration (lib.mkOrder 900 nushellIntegration);
        zsh.envExtra = lib.mkIf cfg.enableZshIntegration (lib.mkOrder 900 bashIntegration);
      };

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
      }${
        lib.optionalString (
          cfg.pkcs11Whitelist != [ ]
        ) " -P '${lib.concatStringsSep "," cfg.pkcs11Whitelist}'"
      }";
    };

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
          }${
            lib.optionalString (
              cfg.pkcs11Whitelist != [ ]
            ) " -P '${lib.concatStringsSep "," cfg.pkcs11Whitelist}'"
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
  };
}
