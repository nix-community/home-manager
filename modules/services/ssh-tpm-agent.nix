{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    mkPackageOption
    types
    ;
  cfg = config.services.ssh-tpm-agent;

in
{
  meta.maintainers = [ lib.maintainers.yethal ];

  options.services.ssh-tpm-agent = {
    enable = mkEnableOption "SSH agent for TPMs";

    package = mkPackageOption pkgs "ssh-tpm-agent" { };

    keyDir = mkOption {
      type = with types; nullOr path;
      description = "Path of the directory to look for TPM sealed keys in, defaults to $HOME/.ssh if unset";
      default = null;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.ssh-tpm-agent" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user = {
      services.ssh-tpm-agent = {
        Unit = {
          Description = "ssh-tpm-agent service";
          Documentation = "https://github.com/Foxboron/ssh-tpm-agent";
          Requires = "ssh-tpm-agent.socket";
          After = "ssh-tpm-agent.socket";
          RefuseManualStart = true;
        };

        Service = {
          Type = "simple";
          SuccessExitStatus = 2;
          ExecStart = "${lib.getExe cfg.package} -l %t/ssh-tpm-agent.sock${
            lib.optionalString (cfg.keyDir != null) " --key-dir ${cfg.keyDir}"
          }";
          Environment = [
            "SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock"
          ];
          PassEnvironment = [
            "SSH_AGENT_PID"
          ];
        };
      };

      sockets.ssh-tpm-agent = {
        Unit = {
          Description = "SSH TPM agent socket";
          Documentation = "https://github.com/Foxboron/ssh-tpm-agent";
        };

        Socket = {
          ListenStream = "%t/ssh-tpm-agent.sock";
          RuntimeDirectory = "ssh-tpm-agent";
          SocketMode = "0600";
          DirectoryMode = "0700";
          Service = "ssh-tpm-agent.service";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    };

    home.sessionVariables = {
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-tpm-agent.sock";
      SSH_TPM_AUTH_SOCK = "\${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-tpm-agent.sock";
    };
  };
}
