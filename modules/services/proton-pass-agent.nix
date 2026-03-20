{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.proton-pass-agent;
in
{
  meta.maintainers = [ lib.maintainers.delafthi ];

  options.services.proton-pass-agent = {
    enable = lib.mkEnableOption "Proton Pass as a SSH agent";

    package = lib.mkPackageOption pkgs "proton-pass-cli" { };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "proton-pass-agent";
      example = "proton-pass-agent/socket";
      description = ''
        The agent's socket; interpreted as a suffix to {env}`$XDG_RUNTIME_DIR`
        on Linux and `$(getconf DARWIN_USER_TEMP_DIR)` on macOS. This option
        adds the `--socket-path` argument to the command.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "--share-id"
        "--vault-name"
        "MySshKeyVault"
        "--refresh-interval"
        "7200"
      ];
      description = ''
        Options given to `pass-cli ssh-agent shart` when the service is run.

        See <https://protonpass.github.io/pass-cli/commands/ssh-agent/#passphrase-protected-ssh-keys>
        for more information.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };
  };

  config =
    let
      socketPath =
        if pkgs.stdenv.isDarwin then
          "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"
        else
          "$XDG_RUNTIME_DIR/${cfg.socket}";
      cmd = [
        "${lib.getExe' cfg.package "pass-cli"}"
        "ssh-agent"
        "start"
        "--socket-path"
        "${if pkgs.stdenv.isDarwin then socketPath else "%t/${cfg.socket}"}"
      ]
      ++ cfg.extraArgs;
    in
    lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];

      programs =
        let
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

      systemd.user.services.proton-pass-agent = {
        Install.WantedBy = [ "default.target" ];
        Unit = {
          Description = "Proton Pass SSH agent";
          Documentation = "https://protonpass.github.io/pass-cli/commands/ssh-agent/#ssh-agent-integration";
        };
        Service = {
          ExecStart = lib.concatStringsSep " " cmd;
          KeyringMode = "shared";
        };
      };

      launchd.agents.proton-pass-agent = {
        enable = true;
        config = {
          ProgramArguments = [
            (lib.getExe pkgs.bash)
            "-c"
            (lib.concatStringsSep " " cmd)
          ];
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ProcessType = "Background";
          RunAtLoad = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/Proton Pass CLI/ssh-agent-stdout.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/Proton Pass CLI/ssh-agent-stderr.log";
        };
      };
    };
}
