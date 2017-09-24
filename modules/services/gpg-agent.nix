{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gpg-agent;

  gpgInitStr = ''
    GPG_TTY="$(tty)"
    export GPG_TTY
    ${pkgs.gnupg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.gpg-agent = {
      enable = mkEnableOption "GnuPG private key agent";

      defaultCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry is valid to the given number of seconds.
        '';
      };

      defaultCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry used for SSH keys is valid to the given number of seconds.
        '';
      };

      enableSshSupport = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use the GnuPG key agent for SSH keys.
        '';
      };

      noGrab = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Tell the pinentry not to grab the keyboard and mouse. This option should in general not be used to avoid X-sniffing attacks.
        '';
      };

      disableScDaemon = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Do not make use of the scdaemon tool. This option has the effect of disabling the ability to do smartcard operations.
        '';
      };

      writeEnvFile = mkOption {
        type = types.nullOr types.string;
        default = null;
        description = ''
          Often it is required to connect to the agent from a process not being an inferior of gpg-agent and thus the environment variable with the socket name is not available. To help setting up those variables in other sessions, this option may be used to write the information into file
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.file.".gnupg/gpg-agent.conf".text = concatStringsSep "\n" (
        optional cfg.enableSshSupport
          "enable-ssh-support"
        ++
        optional cfg.noGrab
          "no-grab"
        ++
        optional cfg.disableScDaemon
          "disable-scdaemon"
        ++
        optional (cfg.defaultCacheTtl != null)
          "default-cache-ttl ${toString cfg.defaultCacheTtl}"
        ++
        optional (cfg.defaultCacheTtlSsh != null)
          "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
        ++
        optional (cfg.writeEnvFile != null)
          "write-env-file ${toString cfg.writeEnvFile}"
      );

      home.sessionVariables =
        optionalAttrs cfg.enableSshSupport {
          SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh";
        };

      programs.bash.initExtra = gpgInitStr;
      programs.zsh.initExtra = gpgInitStr;
    }

    # The systemd units below are direct translations of the
    # descriptions in the
    #
    #   ${pkgs.gnupg}/share/doc/gnupg/examples/systemd-user
    #
    # directory.
    {
      systemd.user.services.gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
          Requires = "gpg-agent.socket";
          After = "gpg-agent.socket";
          # This is a socket-activated service:
          RefuseManualStart = true;
        };

        Service = {
          ExecStart = "${pkgs.gnupg}/bin/gpg-agent --supervised";
          ExecReload = "${pkgs.gnupg}/bin/gpgconf --reload gpg-agent";
        };
      };

      systemd.user.sockets.gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
        };

        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent";
          FileDescriptorName = "std";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    }

    (mkIf cfg.enableSshSupport {
      systemd.user.sockets.gpg-agent-ssh = {
        Unit = {
          Description = "GnuPG cryptographic agent (ssh-agent emulation)";
          Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = "%t/gnupg/S.gpg-agent.ssh";
          FileDescriptorName = "ssh";
          Service = "gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    })
  ]);
}
