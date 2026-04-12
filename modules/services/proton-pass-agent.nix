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

  imports =
    map
      (shell: lib.mkRemovedOptionModule [ "services" "proton-pass-agent" "enable${shell}Integration" ] "")
      [
        "Bash"
        "Zsh"
        "Fish"
        "Nushell"
      ];

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

      sshAuthSock.initialization = {
        bash = ''export SSH_AUTH_SOCK="${socketPath}"'';
        fish = ''set -x SSH_AUTH_SOCK "${socketPath}"'';
        nushell = "$env.SSH_AUTH_SOCK = ${
          if pkgs.stdenv.isDarwin then
            ''$"(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"''
          else
            ''$"($env.XDG_RUNTIME_DIR)/${cfg.socket}"''
        }";
      };

      systemd.user.services.proton-pass-agent = {
        Install.WantedBy = [ "default.target" ];
        Unit = {
          Description = "Proton Pass SSH agent";
          Documentation = "https://protonpass.github.io/pass-cli/commands/ssh-agent/#ssh-agent-integration";
        };
        Service = {
          ExecStart = lib.concatStringsSep " " cmd;
          Restart = "on-failure";
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
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/Proton Pass CLI/ssh-agent-stdout.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/Proton Pass CLI/ssh-agent-stderr.log";
        };
      };
    };
}
