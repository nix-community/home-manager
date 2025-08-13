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
  meta.maintainers = with lib.maintainers; [
    bmrips
    yethal
  ];

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

    home.sessionVariables = {
      # Override ssh-agent's $SSH_AUTH_SOCK definition since ssh-tpm-agent is a
      # proxy to it.
      SSH_AUTH_SOCK = lib.mkOverride 90 "$XDG_RUNTIME_DIR/ssh-tpm-agent.sock";
      SSH_TPM_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-tpm-agent.sock";
    };

    systemd.user = {
      services.ssh-tpm-agent = lib.mkMerge [
        {
          Unit = {
            Description = "ssh-tpm-agent service";
            Documentation = "https://github.com/Foxboron/ssh-tpm-agent";
            Requires = [ "ssh-tpm-agent.socket" ];
            After = [ "ssh-tpm-agent.socket" ];
            RefuseManualStart = true;
          };
          Service = {
            Environment = "SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock";
            ExecStart =
              let
                inherit (config.services) ssh-agent;
              in
              "${lib.getExe cfg.package} -l %t/ssh-tpm-agent.sock"
              + lib.optionalString (cfg.keyDir != null) " --key-dir ${cfg.keyDir}"
              + lib.optionalString ssh-agent.enable " -A %t/${ssh-agent.socket}";
            SuccessExitStatus = 2;
            Type = "simple";
          };
        }
        (mkIf config.services.ssh-agent.enable {
          Unit = {
            BindsTo = [ "ssh-agent.service" ];
            After = [ "ssh-agent.service" ];
          };
        })
      ];

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
  };
}
