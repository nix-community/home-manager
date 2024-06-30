{ config, options, lib, pkgs, ... }:

let

  cfg = config.services.ssh-agent;

in {
  meta.maintainers = [ lib.hm.maintainers.lheckemann ];

  options = {
    services.ssh-agent = {
      enable = lib.mkEnableOption "OpenSSH private key agent";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.ssh-agent" pkgs
        lib.platforms.linux)
    ];

    home.sessionVariablesExtra = ''
      if [[ -z "$SSH_AUTH_SOCK" ]]; then
        export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent
      fi
    '';

    systemd.user.services.ssh-agent = {
      Install.WantedBy = [ "default.target" ];

      Unit = {
        Description = "SSH authentication agent";
        Documentation = "man:ssh-agent(1)";
      };

      Service = {
        ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent";
      };
    };
  };
}
