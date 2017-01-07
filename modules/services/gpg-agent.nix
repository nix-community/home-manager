{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gpg-agent;

in

{
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

      enableSshSupport = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to use the GnuPG key agent for SSH keys.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.file.".gnupg/gpg-agent.conf".text = concatStringsSep "\n" (
      optional cfg.enableSshSupport
        "enable-ssh-support"
      ++
      optional (cfg.defaultCacheTtl != null)
        "default-cache-ttl ${toString cfg.defaultCacheTtl}"
    );

    home.sessionVariables =
      optionalAttrs cfg.enableSshSupport {
        SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/gnupg/S.gpg-agent.ssh";
      };

    programs.bash.initExtra = ''
      GPG_TTY="$(tty)"
      export GPG_TTY
      gpg-connect-agent updatestartuptty /bye > /dev/null
    '';

    systemd.user.services.gpg-agent = {
      Unit = {
        Description = "GnuPG private key agent";
        IgnoreOnIsolate = true;
      };

      Service = {
        Type = "forking";
        ExecStart = "${pkgs.gnupg}/bin/gpg-agent --daemon --use-standard-socket";
        Restart = "on-abort";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
