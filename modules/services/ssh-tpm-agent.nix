{
  config,
  lib,
  osConfig,
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
      {
        assertion =
          let
            onNixos = config.submoduleSupport.enable;
            inherit (osConfig.security) tpm2;
            groups = osConfig.users.users.${config.home.username}.extraGroups;
          in
          onNixos -> tpm2.enable && lib.elem tpm2.tssGroup groups;
        message = ''
          ssh-tpm-agent: The user has to be a member of the '${osConfig.security.tpm2.tssGroup}' group to access the TPM.
          In your NixoS configuration, set:

            security.tpm2.enable = true;
            users.users.<your_username>.extraGroups = [ config.security.tpm2.tssGroup ];

        '';
      }
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
          };
          Service = {
            Environment = "SSH_TPM_AUTH_SOCK=%t/ssh-tpm-agent.sock";
            ExecStart =
              let
                inherit (config.services) ssh-agent;
              in
              (lib.getExe cfg.package)
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
          Service = "ssh-tpm-agent.service";
          SocketMode = "0600";
        };
        Install.WantedBy = [ "sockets.target" ];
      };
    };
  };
}
