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
        on Linux and `$(getconf DARWIN_USER_TEMP_DIR)` on macOS.
      '';
    };

    share-id = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Share ID of the vault to load keys from.
      '';
    };

    vault-name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "MySshKeysVault";
      description = ''
        Name of the vault to load keys from.
      '';
    };

    refresh-interval = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 7200;
      description = ''
        Interval in seconds to refresh SSH keys from Proton Pass.
        Enter a value of 0 to disable. Defaults to 3600.
      '';
    };

    create-new-identities = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "MySshKeysVault";
      description = ''
        Automatically create new SSH key items in the specified vault when
        identities are added via ssh-add. Specify either a vault name or share
        ID.
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
        "${socketPath}"
      ]
      ++ lib.optionals (!isNull cfg.share-id) [
        "--share-id"
        "${cfg.share-id}"
      ]
      ++ lib.optionals (!isNull cfg.vault-name) [
        "--vault-name"
        "${cfg.vault-name}"
      ]
      ++ lib.optionals (!isNull cfg.refresh-interval) [
        "--refresh-interval"
        "${toString cfg.refresh-interval}"
      ]
      ++ lib.optionals (!isNull cfg.create-new-identities) [
        "--create-new-identities"
        "${cfg.create-new-identities}"
      ];
    in
    lib.mkIf cfg.enable {

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
        };
        Service.ExecStart = lib.concatStringsSep " " cmd;
      };

      launchd.agents.proton-pass-agent = {
        enable = true;
        config = {
          ProgramArguments = [
            (lib.getExe pkgs.bash)
            "-c"
            (lib.concatStringSep " " cmd)
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
