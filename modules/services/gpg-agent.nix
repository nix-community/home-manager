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
          Set the time a cache entry is valid to the given number of
          seconds.
        '';
      };

      defaultCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry used for SSH keys is valid to the
          given number of seconds.
        '';
      };

      enableSshSupport = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use the GnuPG key agent for SSH keys.
        '';
      };

      grabKeyboardAndMouse = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Tell the pinentry to grab the keyboard and mouse. This
          option should in general be used to avoid X-sniffing
          attacks. When disabled, this option passes
          <option>no-grab</option> setting to gpg-agent.
        '';
      };

      enableScDaemon = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Make use of the scdaemon tool. This option has the effect of
          enabling the ability to do smartcard operations. When
          disabled, this option passes
          <option>disable-scdaemon</option> setting to gpg-agent.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.file.".gnupg/gpg-agent.conf".text = concatStringsSep "\n" (
        optional (cfg.enableSshSupport) "enable-ssh-support"
        ++
        optional (!cfg.grabKeyboardAndMouse) "no-grab"
        ++
        optional (!cfg.enableScDaemon) "disable-scdaemon"
        ++
        optional (cfg.defaultCacheTtl != null)
          "default-cache-ttl ${toString cfg.defaultCacheTtl}"
        ++
        optional (cfg.defaultCacheTtlSsh != null)
          "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
      );

      home.sessionVariables =
        optionalAttrs cfg.enableSshSupport {
          SSH_AUTH_SOCK =
            if config.home.sessionVariableSetter == "pam"
            then "\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh"
            else "$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)";
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
